import type {
  CarbonActionPlanItemSchema,
  EstimateCarbonBody,
  EstimateCarbonResponse,
} from './calculator.schema';
import type { Static } from '@sinclair/typebox';

type ActionPlanItem = Static<typeof CarbonActionPlanItemSchema>;

export class CalculatorService {
  private static instance: CalculatorService;

  public static getInstance(): CalculatorService {
    if (!CalculatorService.instance) {
      CalculatorService.instance = new CalculatorService();
    }
    return CalculatorService.instance;
  }

  public calculate(body: EstimateCarbonBody): EstimateCarbonResponse {
    // 1. Electricity (Units in kWh, fallback from ₹ bill at average ~₹6.50/unit)
    let unitsKwh = body.monthlyElectricityUnitsKwh;
    if (unitsKwh === undefined || unitsKwh === null) {
      const bill = body.monthlyElectricityBillRupees || 1200;
      unitsKwh = Math.round(bill / 6.5);
    }
    // CEA Indian Grid Factor: 0.82 kg CO2e / kWh
    const monthlyElectricityCo2 = unitsKwh * 0.82;
    const yearlyElectricityCo2 = Math.round(monthlyElectricityCo2 * 12 * 10) / 10;

    // 2. Cooking Fuel
    let monthlyCookingCo2 = 0;
    if (body.cookingFuelType === 'LPG_CYLINDER') {
      // 1 cylinder ~ 14.2 kg LPG produces ~ 42.5 kg CO2e
      monthlyCookingCo2 = body.cookingMonthlyQuantity * 42.5;
    } else if (body.cookingFuelType === 'PNG_PIPED') {
      // 1 SCM PNG produces ~ 1.9 kg CO2e
      monthlyCookingCo2 = body.cookingMonthlyQuantity * 1.9;
    } else {
      // Electric Induction: ~ 35 kWh/month
      monthlyCookingCo2 = 35 * 0.82;
    }
    const yearlyCookingCo2 = Math.round(monthlyCookingCo2 * 12 * 10) / 10;

    // 3. Commute
    // Daily km to annual km (300 working/travel days)
    const annualCommuteKm = body.dailyCommuteKm * 300;
    let emissionFactorPerKm = 0.045; // default 2-wheeler

    switch (body.commuteMode) {
      case 'PETROL_CAR':
        emissionFactorPerKm = 0.18;
        break;
      case 'DIESEL_CAR':
        emissionFactorPerKm = 0.17;
        break;
      case 'PETROL_2WHEELER':
        emissionFactorPerKm = 0.045;
        break;
      case 'EV_CAR':
        emissionFactorPerKm = 0.075;
        break;
      case 'EV_2WHEELER':
        emissionFactorPerKm = 0.015;
        break;
      case 'PUBLIC_BUS_METRO':
        emissionFactorPerKm = 0.028;
        break;
      case 'BICYCLE_WALK':
        emissionFactorPerKm = 0.0;
        break;
    }
    const yearlyCommuteCo2 = Math.round(annualCommuteKm * emissionFactorPerKm * 10) / 10;

    // 4. Diet & Waste baseline in Gujarat
    let yearlyDietWasteCo2 = 250; // Gujarati lacto-vegetarian baseline
    if (body.dietType === 'VEGAN') {
      yearlyDietWasteCo2 = 180;
    } else if (body.dietType === 'NON_VEGETARIAN') {
      yearlyDietWasteCo2 = 550;
    }

    const totalYearlyKgCO2e =
      Math.round((yearlyElectricityCo2 + yearlyCookingCo2 + yearlyCommuteCo2 + yearlyDietWasteCo2) * 10) / 10;
    const totalMonthlyKgCO2e = Math.round((totalYearlyKgCO2e / 12) * 10) / 10;

    // Percentages
    const pElec = totalYearlyKgCO2e > 0 ? Math.round((yearlyElectricityCo2 / totalYearlyKgCO2e) * 100) : 0;
    const pCook = totalYearlyKgCO2e > 0 ? Math.round((yearlyCookingCo2 / totalYearlyKgCO2e) * 100) : 0;
    const pComm = totalYearlyKgCO2e > 0 ? Math.round((yearlyCommuteCo2 / totalYearlyKgCO2e) * 100) : 0;
    const pDiet = Math.max(0, 100 - (pElec + pCook + pComm));

    // Benchmarking vs Gujarat Average (1,850 kg CO2e/year/capita)
    const gujaratAverage = 1850;
    const indiaAverage = 1910;
    const globalAverage = 4500;

    let percentileVsGujarat = 50;
    let rating = 'Conscious Citizen 🌿';

    if (totalYearlyKgCO2e < 1200) {
      percentileVsGujarat = 88;
      rating = 'Mission LiFE Eco Guardian 🏆';
    } else if (totalYearlyKgCO2e < 1850) {
      percentileVsGujarat = 68;
      rating = 'Green Gujarat Champion 🥇';
    } else if (totalYearlyKgCO2e < 2800) {
      percentileVsGujarat = 42;
      rating = 'Average Energy Consumer ⚡';
    } else {
      percentileVsGujarat = 18;
      rating = 'High Carbon Footprint ⚠️';
    }

    // Actionable High-Impact Plan tailored to inputs
    const actionPlan: ActionPlanItem[] = [];

    // AC Thermostat optimization (if electricity > 150 units)
    if (unitsKwh > 150) {
      actionPlan.push({
        title: 'AC 24°C Comfort Setting',
        description: 'Raising your AC from 20°C to 24°C reduces power draw by ~24% during warm Gujarat summers.',
        annualSavingsRupees: 3800,
        annualCo2ReductionKg: 480,
        difficulty: 'EASY',
        icon: '❄️',
      });
    }

    // Rooftop Solar (PM Surya Ghar)
    if (unitsKwh > 200) {
      actionPlan.push({
        title: 'PM Surya Ghar Rooftop Solar (3 kW)',
        description: 'Generate clean solar power with Gujarat subsidies, offsetting up to 80% of your power bill.',
        annualSavingsRupees: 28500,
        annualCo2ReductionKg: 2950,
        difficulty: 'HIGH_IMPACT',
        icon: '☀️',
      });
    }

    // Commute electrification
    if (body.commuteMode.includes('PETROL') || body.commuteMode.includes('DIESEL')) {
      actionPlan.push({
        title: 'Switch to Electric / BRTS Transit',
        description: 'Adopting an EV 2-wheeler or Ahmedabad/Surat BRTS cuts your commute fuel bill by 75%.',
        annualSavingsRupees: 18200,
        annualCo2ReductionKg: 780,
        difficulty: 'MODERATE',
        icon: '🛵',
      });
    }

    // Standby Phantom Power Sweep
    actionPlan.push({
      title: 'Night Wall Socket Sweep (9 PM)',
      description: 'Switching off idle TV set-top boxes, microwave displays, and chargers stops vampire load.',
      annualSavingsRupees: 1400,
      annualCo2ReductionKg: 180,
      difficulty: 'EASY',
      icon: '🔌',
    });

    return {
      totalYearlyKgCO2e,
      totalMonthlyKgCO2e,
      breakdown: {
        electricityKgCO2e: yearlyElectricityCo2,
        cookingKgCO2e: yearlyCookingCo2,
        commuteKgCO2e: yearlyCommuteCo2,
        dietWasteKgCO2e: yearlyDietWasteCo2,
      },
      percentages: {
        electricity: pElec,
        cooking: pCook,
        commute: pComm,
        dietWaste: pDiet,
      },
      benchmarks: {
        gujaratAverageKgCO2e: gujaratAverage,
        indiaAverageKgCO2e: indiaAverage,
        globalAverageKgCO2e: globalAverage,
        percentileVsGujarat,
        rating,
      },
      actionPlan,
    };
  }
}
