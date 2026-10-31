'use client';
import {useEffect,useState} from 'react';
import {useUrja} from '@/contexts/UrjaContext';
import {Title,Card,Mascot} from '@/components/ui/Primitives';
export default function Page(){
 const {state,setState}=useUrja();
 const [evening,setEvening]=useState<boolean|null>(null);
 useEffect(()=>{setEvening(new Date().getHours()>=18)},[]);
 return <><Title eyebrow="A FRIENDLY CHECK-IN">Your reminders</Title><Mascot>Small actions matter. What could you try today?</Mascot><Card><h3>{evening===null?'💡 Daily reminder':evening?'🌙 Evening reminder':'☀️ Today’s idea'}</h3><p>{evening===null?'Choose a small energy-saving action today.':evening?'Check whether lights or fans are running in empty rooms.':'Make the most of natural daylight when possible.'}</p><label className="reminder-setting"><input type="checkbox" checked={state.reminders} onChange={e=>setState(s=>({...s,reminders:e.target.checked}))}/> Show in-app reminders</label><p className="note">Demo reminder only. No background push notifications or live grid alerts.</p></Card></>;
}
