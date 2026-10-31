'use client';
import Link from 'next/link';
import {Title,Mascot} from '@/components/ui/Primitives';
const destinations=[
 ['/tips','💡','Green tips for my home','Easy suggestions based on your routine'],
 ['/reminders','🔔','Gentle reminders','Helpful check-in ideas'],
 ['/community','🤝','Community challenges','Join a local demo challenge'],
 ['/solar','☀️','Rooftop solar explorer','Estimate what solar could mean for you'],
 ['/resources','🧭','Solar resources','Find helpful official portals'],
 ['/admin-demo','📊','GEDA admin preview','Explore example regional statistics'],
 ['/settings','🔒','My data and privacy','Download or clear your progress']
];
export default function Explore(){return <><Title eyebrow="KEEP EXPLORING">More with Urja</Title><Mascot mood="waving">Discover small ways to save energy, learn about solar, and grow together.</Mascot><div className="chapterlist">{destinations.map(([href,icon,title,description])=><Link href={href} className="chapter" key={href}><span className="num">{icon}</span><span><strong>{title}</strong><small>{description}</small></span><span className="arrow">→</span></Link>)}</div></>}
