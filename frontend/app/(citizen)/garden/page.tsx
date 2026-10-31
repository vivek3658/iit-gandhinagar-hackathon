'use client';
import {useRouter} from 'next/navigation';
import Garden from '@/features/garden/Garden';
export default function Page(){const router=useRouter();return <Garden go={(path:string)=>router.push(`/${path}`)}/>;}
