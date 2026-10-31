export type TravelMode='walk'|'bus'|'bike'|'car';
export interface Profile {name:string;members:number;units:number;fans:number;lights:number;ac:number;fanHours:number;vehicle:TravelMode;km:number}
export interface Reading {month:string;units:number}
export interface Experiment {type:string;start:string;logs:Record<string,{result:string;minutes:number}>}
export interface UrjaState {chapter:number;step:number;xp:number;completedChapters:Record<string,boolean>;quizDone:Record<string,boolean>;profile:Profile;readings:Reading[];missionLogs:Record<string,{date:string;selfReported?:boolean}>;experiment:Experiment|null;city:string;community:{joined:boolean;logs:Record<string,boolean>};reminders:boolean}
