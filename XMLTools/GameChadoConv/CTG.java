//CTG.java

import conv.chadxtogame.GameWriter;

import java.io.*;
import java.util.*;

public class CTG {

	public static void main(String argv []) {
		String infile=null,outfile=null;
		int DistStart = 0;
		int DistEnd = 0;
		boolean geneOnly = false;
		String NewSeqName = null;
		for(int i=0;i<argv.length;i++){
                        if(argv[i]!=null){
				if(argv[i].startsWith("-")){
					if(argv[i].startsWith("-D")){
						String d = argv[i].substring(2);
						StringTokenizer stok = new StringTokenizer(d,",");
						if(stok.hasMoreTokens()){
							String ds = stok.nextToken();
							try{
								DistStart = Integer.decode(ds).intValue();
							}catch(Exception ex){
							}
						}
						if(stok.hasMoreTokens()){
							String ds = stok.nextToken();
							try{
								DistEnd = Integer.decode(ds).intValue();
							}catch(Exception ex){
							}
						}
						if(stok.hasMoreTokens()){
							NewSeqName = stok.nextToken();
						}
					}else if(argv[i].startsWith("-g")){
						geneOnly = true;
                                        }
				}else{
					if(infile==null){//FIRST
						infile = argv[i];
					}else if(outfile==null){//SECOND
						outfile = argv[i];
					}
				}
			}
		}
		GameWriter rd = new GameWriter(infile,outfile,DistStart,DistEnd,NewSeqName,geneOnly);
		rd.ChadoToGame();
	}
}


