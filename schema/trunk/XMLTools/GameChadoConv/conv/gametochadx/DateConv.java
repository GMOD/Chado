//DateConv
//REDUNDANT WITH FILE IN conv.chadxtogame for convenience
//package conv.util;
package conv.gametochadx;

import java.util.*;
import java.io.*;
import java.text.*;

public class DateConv {
private int m_start=0;
private int m_end=0;
private String m_src = null;
private static SimpleDateFormat GameFormat = new SimpleDateFormat(
		"EEE MMM d HH:mm:ss z yyyy");
private static SimpleDateFormat HeterochromatinFormat = new SimpleDateFormat(
		"EEE MMM d HH:mm:ss yyyy");
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
			System.out.println("\tRET "+tmp);
			return tmp;
		}else{
			//SEE IF IT IS OF THE FORMAT THAT Chris Smith USES FOR HETEROCHROMATIN
			//System.out.println("CHRIS SMITHS DATE FORMAT");
			String csdate = HeterochromatinDateToChadoDate(the_GameDate);
			if(csdate!=null){
				System.out.println("\tHET DATE<"+csdate+">");
				return csdate;
			}else{
				System.out.println("\tRET NULL");
				return "NULL";
			}
		}
	}

	public static String HeterochromatinDateToChadoDate(String the_GameDate){
		//System.out.println("CONVERTING HETEROCHROMATIN DATE<"+
		//		the_GameDate+"> TO CHADODATE");
		ParsePosition pos = new ParsePosition(0);
		Date dt = HeterochromatinFormat.parse(the_GameDate,pos);
		if(dt!=null){
			String tmp = ChadoFormat.format(dt);
			//System.out.println("\t"+tmp);
			return tmp;
		}else{
			return null;
		}
	}

	public static String ChadoDateToGameDate(String the_ChadoDate){
		System.out.println("CONVERTING CHADODATE<"+
				the_ChadoDate+"> TO GAMEDATE");
		ParsePosition pos = new ParsePosition(0);
		Date dt = ChadoFormat.parse(the_ChadoDate,pos);
		if(dt!=null){
			String tmp = GameFormat.format(dt);
			//System.out.println("\t"+tmp);
			return tmp;
		}else{
			System.out.println("\tNULL");
			return "NULL";
		}
	}

	public static String ChadoDateToTimestamp(String the_ChadoDate){
		//System.out.println("CONVERTING CHADODATE<"+
		//		the_ChadoDate+"> TO TIMESTAMP");
		ParsePosition pos = new ParsePosition(0);
		Date dt = ChadoFormat.parse(the_ChadoDate,pos);
		if(dt!=null){
			String tmp = (""+dt.getTime());
			//System.out.println("\t"+tmp);
			return tmp;
		}else{
			//System.out.println("\t0");
			return "0";
		}
	}

	public static String GameDateToTimestamp(String the_ChadoDate){
		System.out.println("CONVERTING GAMEDATE<"+
				the_ChadoDate+"> TO TIMESTAMP");
		ParsePosition pos = new ParsePosition(0);
		Date dt = GameFormat.parse(the_ChadoDate,pos);
		if(dt!=null){
			String tmp = (""+dt.getTime());
			//System.out.println("\t"+tmp);
			return tmp;
		}else{
			System.out.println("PROBLEMHERE");
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
		outdate = DateConv.ChadoDateToTimestamp(chadodate);
		System.out.println("CHADO IN<"+chadodate+"> GAME TIMESTAMP OUT<"+outdate+">");
	}
}

