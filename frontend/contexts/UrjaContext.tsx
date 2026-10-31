'use client';
import {createContext,useContext,useEffect,useMemo,useState} from 'react';
import type {ReactNode,Dispatch,SetStateAction} from 'react';
import type {UrjaState,Profile} from '@/types/urja';
import {initialState,readState,persistState} from '@/lib/storage';
interface UrjaStore {state:UrjaState;setState:Dispatch<SetStateAction<UrjaState>>;patch:(partial:Partial<UrjaState>)=>void;earn:(points:number)=>void;updateProfile:(partial:Partial<Profile>)=>void;ready:boolean;notice:string;notify:(message:string)=>void;dismiss:()=>void}
const Context=createContext<UrjaStore|null>(null);
export function UrjaProvider({children}:{children:ReactNode}){const [state,setState]=useState<UrjaState>(initialState);const [ready,setReady]=useState(false);const [notice,setNotice]=useState('');useEffect(()=>{setState(readState());setReady(true)},[]);useEffect(()=>{if(ready)persistState(state)},[state,ready]);const value=useMemo<UrjaStore>(()=>({state,setState,patch:partial=>setState(s=>({...s,...partial})),earn:points=>setState(s=>({...s,xp:s.xp+points})),updateProfile:partial=>setState(s=>({...s,profile:{...s.profile,...partial}})),ready,notice,notify:setNotice,dismiss:()=>setNotice('')}),[state,ready,notice]);return <Context.Provider value={value}>{children}</Context.Provider>}
export function useUrja(){const v=useContext(Context);if(!v)throw new Error('UrjaProvider missing');return v}
