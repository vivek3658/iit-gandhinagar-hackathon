'use client';
import {useRouter} from 'next/navigation';
import Story from '@/features/story/Story';
export default function Page(){const router=useRouter();return <Story go={(path:string)=>router.push(`/${path}`)}/>;}
