//DateConv
//package conv.util;
package conv.chadxtogame;

import java.util.*;
import java.io.*;
import java.text.*;

public class DateConv {
private int m_start=0;
private int m_end=0;
private String m_src = null;
private static SimpleDateFormat GameFormat = new SimpleDateFormat(
		"EEE MMM d HH:mm:ss z yyyy");
private static SimpleDateFormat ChadoFormat = new SimpleDateFormat(
		"yyyy'-'MM'-'dd HH:mm:ss");

	public DateConv(){
	}


	public static String GameDateToChadoDate(String the_GameDate){
		System.out.println("CONVERTING GAMEDATE<"+
				the_GameDate+"> TO CHADODATE");
		ParsePosition pos = new ParsePosition(0);
		Date dt = GameFormat.parse(the_GameDate,pos);
		if(dt!=null){
			String tmp = ChadoFormat.format(dt);
			System.out.println("\t"+tmp);
			return tmp;
		}else{
			System.out.println("\tNULL");
			return "NULL";
		}
	}

	public static String ChadoDateToGameDate(String the_ChadoDate){
		System.out.println("CONVERTING CHADODATE<"+
				the_ChadoDate+"> TO GAMEDATE");
		ParsePosition pos = new ParsePosition(0);
		Date dt = ChadoFormat.parse(the_ChadoDate,pos);
		if(dt!=null){
			String tmp = GameFormat.format(dt);
			System.out.println("\t"+tmp);
			return tmp;
		}else{
			System.out.println("\tNULL");
			return "NULL";
		}
	}

	public static String ChadoDateToGameTimestamp(String the_ChadoDate){
		System.out.println("CONVERTING CHADODATE<"+
				the_ChadoDate+"> TO GAMETIMESTAMP");
		ParsePosition pos = new ParsePosition(0);
		Date dt = ChadoFormat.parse(the_ChadoDate,pos);
		if(dt!=null){
			String tmp = (""+dt.getTime());
			System.out.println("\t"+tmp);
			return tmp;
		}else{
			System.out.println("\t0");
			return "0";
		}
	}

	public static String getCurrentDate(){
		Date dt = new Date(System.currentTimeMillis());
		return dt.toString();
	}

	public static String GameTimestampToChadoDate(String the_Timestamp){
		long gametimestamp = 0;
		try{
			gametimestamp = Long.decode(the_Timestamp).longValue();
		}catch(Exception ex){
		}
		Date dt = new Date(gametimestamp);
		if(dt!=null){
			return ChadoFormat.format(dt);
		}else{
			return "0";
		}
	}

	public static void main(String args[]){
		String gamedate = "Thu Mar 07 16:48:36 EDT 2002";
		String outdate = DateConv.GameDateToChadoDate(gamedate);
		//System.out.println("RES IN<"+indate+"> OUT<"+outdate+">");
		String gametimestamp = "1052845690000";
		//outdate = DateConv.GameTimestampToChadoDate(gametimestamp);
		//System.out.println("RES IN<"+intimestamp+"> OUT<"+outdate+">");
		String chadodate = "2003-09-23 21:33:39.739009";
		outdate = DateConv.ChadoDateToGameTimestamp(chadodate);
		System.out.println("CHADO IN<"+chadodate+"> GAME TIMESTAMP OUT<"+outdate+">");
	}
}

//a time in game such as
//<date timestamp="1052845690000">Tue May 13 13:08:10 EDT 2003</date>
//
//should become in chado
//<timeaccessioned>2003-09-23 21:33:39.739009<timeaccessioned>

/***********************
		try{
			m_start = Integer.decode(the_start).intValue();
			m_end = Integer.decode(the_end).intValue();
		}catch(Exception ex){
			System.out.println("SPAN STR ERROR <"
					+the_start+"><"+the_end+">");
			ex.printStackTrace();
		}

	public DateConv(String the_start,String the_end,String the_src){
		this(the_start,the_end);
		m_src = the_src;
	}

	public DateConv(int the_start,int the_end){
		m_start = the_start;
		m_end = the_end;
	}

	public DateConv(int the_start,int the_end,String the_src){
		this(the_start,the_end);
		m_src = the_src;
	}

	public int getStart(){
		return m_start;
	}

	public int getEnd(){
		return m_end;
	}

	public void setSrc(String the_src){
		m_src = the_src;
	}

	public String getSrc(){
		return m_src;
	}

	public int getLength(){
		if(m_start<m_end){
//PEILI
			return (m_end-m_start);
			//return (m_end-m_start+1);
		}else{
//PEILI
			return (m_start-m_end);
			//return (m_start-m_end+1);
		}
	}

	public boolean isForward(){
		if(m_end>m_start){
			return true;
		}else{
			return false;
		}
	}

	public String toString(){
		return (m_start+".."+m_end);
	}

	public DateConv advance(int the_amt){
		if(m_end>m_start){
			return (new DateConv((m_start+the_amt-1),(m_end+the_amt),m_src));
		}else{
			return (new DateConv((m_start+the_amt),(m_end+the_amt-1),m_src));
		}
	}

	public DateConv retreat(int the_amt){
		if(m_end>m_start){
			return (new DateConv((m_start-the_amt+1),(m_end-the_amt),m_src));
		}else{
			return (new DateConv((m_start-the_amt),(m_end-the_amt+1),m_src));
		}
	}

	public DateConv union(DateConv the_sp){
		int minStart = m_start;
		int maxEnd = m_end;
		if(the_sp.isForward()){
			if(minStart>the_sp.getStart()){
				minStart = the_sp.getStart();
			}
			if(maxEnd<the_sp.getEnd()){
				maxEnd = the_sp.getEnd();
			}
		}else{
			if(minStart<the_sp.getStart()){
				minStart = the_sp.getStart();
			}
			if(maxEnd>the_sp.getEnd()){
				maxEnd = the_sp.getEnd();
			}
		}
		return new DateConv(minStart,maxEnd,m_src);
	}

	public boolean precedes(DateConv the_sp){
                if(the_sp==null){
                        return false;
                }
                if((isForward())&&(the_sp.isForward())){
                        if(getStart()<the_sp.getStart()){
                                return true;
                        }
                }else if((!isForward())&&(!isForward())){
                        if(getStart()>the_sp.getStart()){
                                return true;
                        }
                }else if((isForward())&&(!the_sp.isForward())){
                        System.out.println("FEATLOC PRECEDES() MIX1");
                }else if((!isForward())&&(the_sp.isForward())){
                        System.out.println("FEATLOC PRECEDES() MIX2");
                }
                return false;
	}

	public boolean contains(DateConv the_sp){
		if(the_sp==null){
			return false;
		}
		int min = getStart();
		int max = getEnd();
		if(min>max){
			int tmp = min;
			min = max;
			max = tmp;
		}
		if((the_sp.getStart()>=min)
				&&(the_sp.getStart()<=max)
				&&(the_sp.getEnd()>=min)
				&&(the_sp.getEnd()<=max)){
			return true;
		}
		return false;
	}

	public void Display(int the_depth){
		String offsetTxt = "";
		for(int i=0;i<the_depth;i++){
			offsetTxt += "\t";
		}
		System.out.println(offsetTxt+" DateConv <"+toString()+">");
	}
***********************/





