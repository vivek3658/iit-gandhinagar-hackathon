'use client';
import type {ReactNode} from 'react';
import Image from 'next/image';
import {useUrja} from '@/contexts/UrjaContext';
export function Title({eyebrow,children}:{eyebrow:string;children:ReactNode}){return <div className="heading"><div><div className="eyebrow">{eyebrow}</div><h1>{children}</h1></div></div>}
export function Card({children,className=''}:{children:ReactNode;className?:string}){return <div className={`card ${className}`}>{children}</div>}
export function Button({children,onClick,alt=false,disabled=false}:{children:ReactNode;onClick:()=>void;alt?:boolean;disabled?:boolean}){return <button type="button" className={`btn full ${alt?'alt':''}`} onClick={onClick} disabled={disabled}>{children}</button>}
export function Mascot({children,mood='talking'}:{children:ReactNode;mood?:string}){return <div className="guide"><Image src={`/assets/urja_${mood}_cutout.webp`} alt="Urja, your green friend" width={125} height={150}/><div className="speech"><small>✦ URJA SAYS</small><p>{children}</p></div></div>}
export function NumberField({label,value,onChange,min=0,max=100000}:{label:string;value:string|number;onChange:(value:string)=>void;min?:number;max?:number}){return <label className="field"><span className="input-label">{label}</span><input type="number" min={min} max={max} value={value} onChange={e=>onChange(e.target.value)}/></label>}
export function Banner(){return <div className="demo-banner">🧪 Prototype mode: community rankings and administrator totals are examples, not live verified data.</div>}
export function Notice(){const {notice,dismiss}=useUrja();return notice?<div className="message-toast" role="status">{notice}<button onClick={dismiss} aria-label="Dismiss message">×</button></div>:null}
