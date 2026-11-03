export const chapters = [
  ['🌫️', 'The Invisible Problem', 'Meet greenhouse gases and learn why everyday choices matter.'],
  [
    '🏠',
    'The Energy Detectives',
    'Read a bill, notice household patterns, and make a starting estimate.',
  ],
  ['🚲', 'Everyday Journeys', 'Compare travel choices while keeping safety and distance in mind.'],
  [
    '🌍',
    'Your Invisible Footprint',
    'Understand what a partial footprint estimate can—and cannot—tell you.',
  ],
  ['🌱', 'The First Green Change', 'Choose one comfortable habit and observe it for a week.'],
  [
    '☀️',
    'Power of Sunshine',
    'Explore rooftop solar and questions to ask before making a decision.',
  ],
  ['🤝', 'Together We Grow', 'Make an optional household promise and invite others respectfully.'],
  [
    '🌈',
    'A Greener Tomorrow',
    'Celebrate progress, learn from setbacks, and choose your next step.',
  ],
];

export const chapterNarratives = [
  [
    'Urja’s garden looks peaceful, but the choices made in homes and on roads are connected to the air we share. Some activities release greenhouse gases such as carbon dioxide (CO₂), which trap heat in the atmosphere.',
    'CO₂ is invisible, and it is not the same thing as smoke or smog. We cannot judge our impact by appearance alone, so this journey starts with curiosity: notice a habit, learn what it uses, and look for a change that feels realistic.',
  ],
  [
    'The Energy Detectives begin with a familiar clue: a monthly electricity bill. Its units, usually shown as kWh, describe energy used over a billing period. A reading can help you understand a pattern, but one month by itself does not explain every reason the number changed.',
    'Weather, household size, appliances, and time spent at home all matter. Record what you know, label anything estimated, and treat the result as a starting point—not a score or a judgement of your family.',
  ],
  [
    'A journey has more than one possible route. Walking, cycling, shared rides, and public transport can have different impacts from a trip made by a private vehicle, but distance, occupancy, local services, and the vehicle itself all affect the comparison.',
    'Choose only options that are safe and practical for you. This chapter uses a simple estimate to build awareness; it is not a measurement of a particular vehicle or a promise of emissions avoided.',
  ],
  [
    'Your footprint here combines only the information you entered about electricity and a usual commute. It leaves out many parts of daily life, including cooking fuels, food, shopping, and other travel, so it is intentionally a partial picture.',
    'A useful estimate should come with its assumptions. If a number changes, check whether your usage or the inputs changed too. Use the result to ask better questions and track consistent readings—not to compare households as if they were identical.',
  ],
  [
    'Big changes are easier to sustain when they begin with one small experiment. Pick a habit that fits your home, such as switching off an unused light when it is safe, and try it for seven days.',
    'Notice what helped and what got in the way. Missing a day is information, not failure; adjust the reminder or choose a more comfortable action. Progress comes from repeatable choices, not from making a promise that does not suit your circumstances.',
  ],
  [
    'Sunlight can be converted into electricity by rooftop solar panels. Whether a home is suitable depends on factors such as roof shade, available space, building permissions, system costs, and local rules.',
    'Learn from official scheme information and qualified providers before making a purchase. A calculator or illustration is only a guide: actual generation and savings depend on the installed system and household conditions.',
  ],
  [
    'A greener routine can be easier when people share ideas. Invite your household to choose one activity together, such as checking for unused lights, and agree on a reminder that feels helpful rather than demanding.',
    'Everyone should be free to participate or decline. This promise stays personal unless people choose to join; it does not automatically enroll family members or share their information.',
  ],
  [
    'Look back at what you learned: how to read an energy clue, question an estimate, and choose a practical experiment. Small actions are valuable when they fit real life and can be repeated over time.',
    'There is no need to be perfect. Keep tracking consistent information, celebrate what worked, and choose a new step when you are ready. Urja’s garden grows through steady learning and shared care.',
  ],
];

export const missions = [
  {
    id: 'light',
    icon: '💡',
    title: 'Switch off an unused light',
    description: 'Look for a light that nobody needs right now.',
    xp: 15,
  },
  {
    id: 'fan',
    icon: '🌬️',
    title: 'Check an empty-room fan',
    description: 'Switch it off safely when no one needs it.',
    xp: 20,
  },
  {
    id: 'daylight',
    icon: '☀️',
    title: 'Use daylight',
    description: 'Try sunlight instead of a lamp where it works.',
    xp: 15,
  },
  {
    id: 'fridge',
    icon: '🧊',
    title: 'Check the fridge door',
    description: 'Make sure its door closes fully.',
    xp: 15,
  },
  {
    id: 'standby',
    icon: '🔌',
    title: 'Switch off unused power',
    description: 'Turn off an unused device when safe.',
    xp: 20,
  },
  {
    id: 'audit',
    icon: '🔎',
    title: 'Find two easy changes',
    description: 'Look for two ways to avoid wasting energy.',
    xp: 25,
  },
  {
    id: 'walk',
    icon: '🚶',
    title: 'Walk a short journey',
    description: 'Choose a safe walking trip when practical.',
    xp: 20,
  },
  {
    id: 'share',
    icon: '🤝',
    title: 'Share a green tip',
    description: 'Tell someone one simple way to save energy.',
    xp: 15,
  },
  {
    id: 'water',
    icon: '💧',
    title: 'Save some water',
    description: 'Close a tap when you do not need running water.',
    xp: 15,
  },
  {
    id: 'learn',
    icon: '📖',
    title: 'Learn a new green idea',
    description: 'Read one tip and share what you learned.',
    xp: 15,
  },
  {
    id: 'washing',
    icon: '🧺',
    title: 'Plan a full wash',
    description: 'Use a suitable load as recommended by your washer.',
    xp: 20,
  },
  {
    id: 'ac',
    icon: '❄️',
    title: 'Check comfortable cooling',
    description: 'Try a moderate AC setting if it feels comfortable.',
    xp: 20,
  },
];
export const cities = [
  'Ahmedabad',
  'Surat',
  'Vadodara',
  'Rajkot',
  'Gandhinagar',
  'Bhavnagar',
  'Other Gujarat city',
];
export const sampleCommunity = [
  { name: 'Green Neighbours', city: 'Ahmedabad', score: 480 },
  { name: 'Sunshine Squad', city: 'Surat', score: 410 },
  { name: 'Eco Explorers', city: 'Vadodara', score: 355 },
];
export const resources = [
  {
    name: 'PM Surya Ghar',
    description: 'Official rooftop solar scheme and application information.',
    url: 'https://pmsuryaghar.gov.in/',
  },
  {
    name: 'GEDA',
    description: 'Gujarat renewable energy guidance and programmes.',
    url: 'https://geda.gujarat.gov.in/',
  },
  {
    name: 'National Rooftop Solar Portal',
    description: 'Explore national rooftop solar resources.',
    url: 'https://solarrooftop.gov.in/',
  },
];
