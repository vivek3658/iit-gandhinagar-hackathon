'use client';
import Link from 'next/link';
import Image from 'next/image';
import {usePathname} from 'next/navigation';
import type {ReactNode} from 'react';
import {useUrja} from '@/contexts/UrjaContext';
import {gardenStage} from '@/lib/calculations';
import {Notice} from '@/components/ui/Primitives';
const tabs=[['/story','📖','Story'],['/garden','🏡','Garden'],['/missions','🧭','Missions'],['/impact','🌿','Impact'],['/explore','✨','Explore']] as const;
export default function AppShell({children}:{children:ReactNode}){const pathname=usePathname();const {state,ready}=useUrja();return <main className="app"><header className="hero"><Image src={`/assets/stage-${gardenStage(state.xp)}.webp`} alt="Your evolving garden" fill priority sizes="(max-width: 470px) 100vw, 470px" style={{objectFit:'cover'}}/><div className="brand">🌱 urja<span style={{color:'#d4a257'}}>.</span></div><div className="topright">✨ {state.xp} XP</div></header><section className="page">{ready?children:<p>Opening your green journey...</p>}</section><nav className="nav" aria-label="Main sections">{tabs.map(([href,icon,label])=><Link key={href} href={href} aria-current={pathname.startsWith(href)?'page':undefined} className={pathname.startsWith(href)?'on':''}><span>{icon}</span>{label}</Link>)}</nav><Notice/></main>}
