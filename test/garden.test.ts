import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app';
import { AuthService } from '../src/modules/auth/auth.service';
import { MascotService } from '../src/modules/mascot/mascot.service';
import { GardenService } from '../src/modules/garden/garden.service';

describe('Garden Sanctuary Module (Grid, Inventory & Resale Tests)', () => {
  let app: FastifyInstance;
  let citizenToken: string;
  let citizenId: string;

  beforeAll(async () => {
    app = buildApp({ logger: false });
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(async () => {
    AuthService.getRepository().clear();
    MascotService.getRepository().clear();
    GardenService.getRepository().clear();

    // Provision a test citizen (starts with 100 bonus Urja Mudra coins)
    const login = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/google',
      payload: { idToken: 'mock_test_token_garden_citizen' },
    });
    const body = JSON.parse(login.body);
    citizenToken = body.accessToken;
    citizenId = body.user.id;
  });

  it('1. GET /api/v1/garden auto-initializes level 1 sanctuary with 3x3 grid & 31 catalog tiles', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/garden',
      headers: { authorization: `Bearer ${citizenToken}` },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);

    expect(body.gridSize).toBe(3); // Level 1 mascot = 3x3 grid
    expect(body.maxOccupancy).toBe(9);
    expect(body.currentOccupiedCount).toBe(0);
    expect(body.citizenCoins).toBe(100);
    expect(body.placedTiles).toEqual([]);
    expect(body.inventory).toEqual([]);
    expect(body.catalog.length).toBe(31);

    // Verify unlocked vs level-locked items
    const grassTile = body.catalog.find((t: { id: string }) => t.id === 'GRASS_TILE');
    expect(grassTile.isUnlocked).toBe(true);

    const banyan = body.catalog.find((t: { id: string }) => t.id === 'HERITAGE_BANYAN');
    expect(banyan.isUnlocked).toBe(false); // Requires level 25
  });

  it('2. POST /api/v1/garden/preview verifies bounds, level requirements, and collision', async () => {
    // A. Valid coordinate
    const validRes = await app.inject({
      method: 'POST',
      url: '/api/v1/garden/preview',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: {
        tileId: 'STONE_PATH',
        x: 1,
        y: 1,
        rotation: 90,
      },
    });
    expect(validRes.statusCode).toBe(200);
    const validBody = JSON.parse(validRes.body);
    expect(validBody.isValid).toBe(true);

    // B. Out of bounds coordinate for 3x3 grid (x=3, y=0)
    const outOfBoundsRes = await app.inject({
      method: 'POST',
      url: '/api/v1/garden/preview',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: {
        tileId: 'STONE_PATH',
        x: 3,
        y: 0,
        rotation: 0,
      },
    });
    expect(outOfBoundsRes.statusCode).toBe(200);
    const oobBody = JSON.parse(outOfBoundsRes.body);
    expect(oobBody.isValid).toBe(false);
    expect(oobBody.message).toContain('out of current grid bounds');

    // C. Level-locked item preview
    const lockedRes = await app.inject({
      method: 'POST',
      url: '/api/v1/garden/preview',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: {
        tileId: 'HERITAGE_BANYAN',
        x: 0,
        y: 0,
      },
    });
    expect(lockedRes.statusCode).toBe(200);
    const lockedBody = JSON.parse(lockedRes.body);
    expect(lockedBody.isValid).toBe(false);
    expect(lockedBody.message).toContain('Requires Mascot Level 25');
  });

  it('3. POST /api/v1/garden/buy-and-place validates coin balance and places tile', async () => {
    // Attempt to buy 500-coin Solar Panel when citizen only has 100 coins
    const failRes = await app.inject({
      method: 'POST',
      url: '/api/v1/garden/buy-and-place',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: {
        tileId: 'SOLAR_PANEL_T1',
        x: 0,
        y: 0,
      },
    });
    expect(failRes.statusCode).toBe(400);
    expect(JSON.parse(failRes.body).message).toContain('Insufficient Urja Mudra');

    // Buy affordable 50-coin Lush Meadow Tile
    const buyRes = await app.inject({
      method: 'POST',
      url: '/api/v1/garden/buy-and-place',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: {
        tileId: 'GRASS_TILE',
        x: 0,
        y: 0,
        rotation: 90,
      },
    });
    expect(buyRes.statusCode).toBe(200);
    const buyBody = JSON.parse(buyRes.body);
    expect(buyBody.success).toBe(true);
    expect(buyBody.remainingCoins).toBe(50); // 100 - 50 = 50
    expect(buyBody.placedTiles.length).toBe(1);
    expect(buyBody.placedTiles[0].tileId).toBe('GRASS_TILE');
    expect(buyBody.placedTiles[0].rotation).toBe(90);

    // Reject placing another tile on the occupied cell (0, 0)
    const duplicateRes = await app.inject({
      method: 'POST',
      url: '/api/v1/garden/buy-and-place',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: {
        tileId: 'EMPTY_LAND',
        x: 0,
        y: 0,
      },
    });
    expect(duplicateRes.statusCode).toBe(400);
    expect(JSON.parse(duplicateRes.body).message).toContain('already occupied');
  });

  it('4. Remove tile to inventory, place back, and sell for 80% refund', async () => {
    // 1. Buy a 100-coin Stone Path at (1, 1)
    const buyRes = await app.inject({
      method: 'POST',
      url: '/api/v1/garden/buy-and-place',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: {
        tileId: 'STONE_PATH',
        x: 1,
        y: 1,
        rotation: 0,
      },
    });
    expect(buyRes.statusCode).toBe(200);
    expect(JSON.parse(buyRes.body).remainingCoins).toBe(0); // 100 - 100 = 0

    // 2. Remove tile from (1, 1) and store in inventory
    const removeRes = await app.inject({
      method: 'POST',
      url: '/api/v1/garden/remove-to-inventory',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: { x: 1, y: 1 },
    });
    expect(removeRes.statusCode).toBe(200);
    const removeBody = JSON.parse(removeRes.body);
    expect(removeBody.placedTiles.length).toBe(0);
    expect(removeBody.inventory.length).toBe(1);
    expect(removeBody.inventory[0].tileId).toBe('STONE_PATH');
    expect(removeBody.inventory[0].sellRefundPrice).toBe(80); // 80% of 100

    const storedInstanceId = removeBody.inventory[0].instanceId;

    // 3. Place back from inventory to (2, 2) with 180° rotation (0 cost)
    const placeRes = await app.inject({
      method: 'POST',
      url: '/api/v1/garden/place-from-inventory',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: {
        instanceId: storedInstanceId,
        x: 2,
        y: 2,
        rotation: 180,
      },
    });
    expect(placeRes.statusCode).toBe(200);
    const placeBody = JSON.parse(placeRes.body);
    expect(placeBody.placedTiles.length).toBe(1);
    expect(placeBody.inventory.length).toBe(0);
    expect(placeBody.placedTiles[0].x).toBe(2);
    expect(placeBody.placedTiles[0].y).toBe(2);
    expect(placeBody.placedTiles[0].rotation).toBe(180);

    // 4. Remove to inventory again
    await app.inject({
      method: 'POST',
      url: '/api/v1/garden/remove-to-inventory',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: { x: 2, y: 2 },
    });

    // 5. Sell tile from inventory for 80% coin recovery
    const sellRes = await app.inject({
      method: 'POST',
      url: '/api/v1/garden/sell',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: { instanceId: storedInstanceId },
    });
    expect(sellRes.statusCode).toBe(200);
    const sellBody = JSON.parse(sellRes.body);
    expect(sellBody.success).toBe(true);
    expect(sellBody.refundCoins).toBe(80);
    expect(sellBody.remainingCoins).toBe(80); // 0 + 80 = 80
    expect(sellBody.inventory.length).toBe(0);
  });

  it('5. Dynamic land growth: Leveling up mascot expands grid to 4x4 (16 tiles)', async () => {
    // Award CO2 savings to reach level 10 (needs 81 kg CO2)
    MascotService.addCo2Savings(citizenId, 100); // 100 kg CO2 = Level 11

    const stateRes = await app.inject({
      method: 'GET',
      url: '/api/v1/garden',
      headers: { authorization: `Bearer ${citizenToken}` },
    });

    const stateBody = JSON.parse(stateRes.body);
    expect(stateBody.mascotLevel).toBeGreaterThanOrEqual(10);
    expect(stateBody.gridSize).toBe(4); // 4x4 grid!
    expect(stateBody.maxOccupancy).toBe(16);

    // Coordinate (3, 3) is now valid!
    const previewRes = await app.inject({
      method: 'POST',
      url: '/api/v1/garden/preview',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: {
        tileId: 'STONE_PATH',
        x: 3,
        y: 3,
      },
    });
    expect(JSON.parse(previewRes.body).isValid).toBe(true);
  });
});
