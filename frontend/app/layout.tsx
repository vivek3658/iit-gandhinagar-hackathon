import type {Metadata} from 'next';
import type {ReactNode} from 'react';
import './globals.css';
import {UrjaProvider} from '@/contexts/UrjaContext';
export const metadata:Metadata={title:'Urja · The Green Chronicles',description:'Small green habits, one day at a time'};
export default function RootLayout({children}:{children:ReactNode}){return <html lang="en"><body><UrjaProvider>{children}</UrjaProvider></body></html>}
