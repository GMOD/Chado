//GameVersionReader.java

//Reads the version string in a GAME file, as put there by apollo.
package conv.gametochadx;

import java.io.*;
import java.util.*;
import java.text.*;

import java.net.URL;
import java.net.URLConnection;

public class GameVersionReader {

	public GameVersionReader(){
	}

	public static String getVerString(String the_fileName){
		try {
			FileReader fr = new FileReader(the_fileName);
			BufferedReader br = new BufferedReader(fr);

			String line = null;
			int lineCnt = 0;
			String subStr = null;
			String modStr = null;
			while((line = br.readLine())!=null){
				int indx = line.lastIndexOf(" version ");
				if(indx>0){
					subStr = line.substring(indx);
					indx = subStr.indexOf("--");
					if(indx>0){
						subStr = subStr.substring(0,indx);
						return subStr.trim();
					}
				}
				indx = line.lastIndexOf("Module");
				if(indx>0){
					modStr = line.trim();
					indx = modStr.indexOf(",v ");
					if(indx>0){
						modStr = modStr.substring(indx+1).trim();
						indx = modStr.indexOf("Exp");
						if(indx>0){
							modStr = modStr.substring(0,indx).trim();
						}
					}
				}
				if(lineCnt>12){
					if(modStr!=null){
						return modStr;
					}
					return null;
				}
				lineCnt++;
			}
		}catch(IOException ioex){
			System.out.println("GameVersionReader Exception");
			ioex.printStackTrace();
		}
		return null;
	}

	public static void main(String args[]){
		String res = GameVersionReader.getVerString("/usr/local/apollo/data-ip/AE003830.Feb.crosby.p.xml");
		System.out.println("RES<"+res+">");
	}
}

