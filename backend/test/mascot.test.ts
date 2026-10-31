import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app';
import { AuthService } from '../src/modules/auth/auth.service';
import { MascotService } from '../src/modules/mascot/mascot.service';

describe('Mascot Module (State Machine & Wardrobe Tests)', () => {
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

    // Provision a test citizen (starts with 100 bonus points)
    const login = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/google',
      payload: { idToken: 'mock_test_token_mascot_user' },
    });
    const body = JSON.parse(login.body);
    citizenToken = body.accessToken;
    citizenId = body.user.id;
  });

  it('1. GET /api/v1/mascot auto-initializes sparrow mascot with default stats', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/mascot/state',
      headers: { authorization: `Bearer ${citizenToken}` },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);

    expect(body.type).toBe('sparrow');
    expect(body.name).toBe('Chirpy');
    expect(body.level).toBe(1);
    expect(body.vitality).toBe(85);
    expect(body.mood).toBe('EXCITED');
    const isNightTime = new Date().getHours() >= 22 || new Date().getHours() < 5;
    expect(body.expression).toBe(isNightTime ? 'nest' : 'excited');
    expect(body.activeProps).toContain(isNightTime ? 'zzz' : 'sparks');
    expect(body.equipped.head).toBeNull();
    expect(body.equipped.face).toBeNull();
    expect(body.equipped.neck).toBeNull();
    expect(body.equipped.held).toBeNull();
    expect(body.equipped.fx).toBeNull();
    expect(body.ownedAccessories).toEqual([]);
    expect(typeof body.dialogue.text).toBe('string');
  });

  it('2. PATCH /api/v1/mascot renames mascot and switches type to squirrel', async () => {
    const res = await app.inject({
      method: 'PATCH',
      url: '/api/v1/mascot',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: {
        name: 'Panku',
        type: 'squirrel',
      },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.name).toBe('Panku');
    expect(body.type).toBe('squirrel');
  });

  it('3. POST /api/v1/mascot/interact boosts vitality and returns dynamic speech', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/mascot/interact',
      headers: { authorization: `Bearer ${citizenToken}` },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.vitality).toBe(90); // 85 + 5
    expect(body.pointsAwarded).toBe(2);
    expect(body.expression).toBe('curious');
    expect(body.activeProps).toContain('sparks');
    expect(body.dialogue.context).toBe('TAP');
  });

  it('4. Wardrobe Shop: lists items and validates slots and pricing', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/mascot/wardrobe',
      headers: { authorization: `Bearer ${citizenToken}` },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.citizenPoints).toBe(50);
    expect(body.items.length).toBeGreaterThanOrEqual(15);

    // Verify slots and pricing
    for (const item of body.items) {
      expect(item.price).toBeGreaterThanOrEqual(50);
      expect(['HEAD', 'FACE', 'NECK', 'HELD', 'FX']).toContain(item.slot);
    }
  });

  it('5. Wardrobe Shop: buys accessory atomically, prevents overspending & duplicates', async () => {
    // Top up to 100 points
    AuthService.getRepository().updateUser(citizenId, { points: 100 });

    // 1. Citizen has 100 points, buys solar cap (price: 100)
    const buyRes = await app.inject({
      method: 'POST',
      url: '/api/v1/mascot/wardrobe/buy',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: { accessoryId: 'acc_head_solar_cap' },
    });

    expect(buyRes.statusCode).toBe(200);
    const buyBody = JSON.parse(buyRes.body);
    expect(buyBody.success).toBe(true);
    expect(buyBody.remainingPoints).toBe(0);
    expect(buyBody.ownedAccessories).toContain('acc_head_solar_cap');

    // 2. Buying again fails (insufficient funds)
    const failRes = await app.inject({
      method: 'POST',
      url: '/api/v1/mascot/wardrobe/buy',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: { accessoryId: 'acc_neck_green_muffler' },
    });
    expect(failRes.statusCode).toBe(400);

    // 3. Buying duplicate fails
    const dupRes = await app.inject({
      method: 'POST',
      url: '/api/v1/mascot/wardrobe/buy',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: { accessoryId: 'acc_head_solar_cap' },
    });
    expect(dupRes.statusCode).toBe(400);
  });

  it('6. Wardrobe Equip: equips owned accessory, blocks unowned or wrong slot', async () => {
    // Top up to 100 points to buy solar cap
    AuthService.getRepository().updateUser(citizenId, { points: 100 });

    // Buy solar cap first
    await app.inject({
      method: 'POST',
      url: '/api/v1/mascot/wardrobe/buy',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: { accessoryId: 'acc_head_solar_cap' },
    });

    // 1. Equip solar cap to HEAD (success)
    const equipRes = await app.inject({
      method: 'POST',
      url: '/api/v1/mascot/wardrobe/equip',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: {
        slot: 'HEAD',
        accessoryId: 'acc_head_solar_cap',
      },
    });

    expect(equipRes.statusCode).toBe(200);
    const equipBody = JSON.parse(equipRes.body);
    expect(equipBody.equipped.head).toBe('acc_head_solar_cap');

    // 2. Equip unowned item to FACE (fails 400)
    const unownedRes = await app.inject({
      method: 'POST',
      url: '/api/v1/mascot/wardrobe/equip',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: {
        slot: 'FACE',
        accessoryId: 'sunnies',
      },
    });
    expect(unownedRes.statusCode).toBe(400);

    // 3. Equip HEAD item into FACE slot (fails 400)
    const wrongSlotRes = await app.inject({
      method: 'POST',
      url: '/api/v1/mascot/wardrobe/equip',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: {
        slot: 'FACE',
        accessoryId: 'acc_head_solar_cap',
      },
    });
    expect(wrongSlotRes.statusCode).toBe(400);

    // 4. Unequip (sets to null)
    const unequipRes = await app.inject({
      method: 'POST',
      url: '/api/v1/mascot/wardrobe/equip',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: {
        slot: 'HEAD',
        accessoryId: null,
      },
    });
    expect(unequipRes.statusCode).toBe(200);
    const unequipBody = JSON.parse(unequipRes.body);
    expect(unequipBody.equipped.head).toBeNull();
  });

  it('7. Curated Seasonal Outfits: lists bundles and equips pieces', async () => {
    const outfitsRes = await app.inject({
      method: 'GET',
      url: '/api/v1/mascot/outfits',
      headers: { authorization: `Bearer ${citizenToken}` },
    });

    expect(outfitsRes.statusCode).toBe(200);
    const outfitsBody = JSON.parse(outfitsRes.body);
    expect(outfitsBody.outfits.length).toBe(6); // spring, summer, autumn, winter, rainy, festive

    const springOutfit = outfitsBody.outfits.find((o: { id: string }) => o.id === 'spring');
    expect(springOutfit.season).toBe('spring');
    expect(springOutfit.head).toBe('flowers');
    expect(springOutfit.neck).toBe('bow');
    expect(springOutfit.fx).toBe('petals');

    // Equip outfit bundle
    const equipOutfitRes = await app.inject({
      method: 'POST',
      url: '/api/v1/mascot/outfits/equip',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: { outfitId: 'spring' },
    });

    expect(equipOutfitRes.statusCode).toBe(200);
    const equipOutfitBody = JSON.parse(equipOutfitRes.body);
    expect(equipOutfitBody.success).toBe(true);
    expect(equipOutfitBody.outfitId).toBe('spring');
  });

  it('8. CO2 Saved Progression: levels up mascot without coins', () => {
    // Add 16 kg of CO2 saved (1600 exp) -> Math.floor(Math.sqrt(1600 / 100)) + 1 = 5
    const mascot = MascotService.addCo2Savings(citizenId, 16);
    expect(mascot.currentExp).toBe(1600);
    expect(mascot.level).toBe(5);
    expect(mascot.nextLevelExp).toBe(2500); // 5^2 * 100
  });
});
