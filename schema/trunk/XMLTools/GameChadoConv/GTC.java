//ChadoWriter

import conv.gametochadx.ChadoWriter;
import conv.gametochadx.GameSaxReader;

import java.io.*;
import java.util.*;

public class GTC {

	public static void main(String argv []) {
		String infile=null,outfile=null;
		int parseflags = GameSaxReader.PARSEALL; //DEFAULT
		int modeflags = ChadoWriter.WRITEALL;
		int seqflags = ChadoWriter.SEQOMIT;
		int tpflags = ChadoWriter.TPOMIT;
		for(int i=0;i<argv.length;i++){
			if(argv[i]!=null){
				if(argv[i].startsWith("-")){
					//FLAG
					if(argv[i].equals("-a")){//ALL
						parseflags = GameSaxReader.PARSEALL;
					}else if(argv[i].equals("-c")){//COMPUTATIONAL_ANALYSIS
						parseflags = GameSaxReader.PARSECOMP;
					}else if(argv[i].equals("-g")){//GENES
						parseflags = GameSaxReader.PARSEGENES;
					}else if(argv[i].equals("-t")){//TRANSACTIONAL CHANGES
						modeflags = ChadoWriter.WRITECHANGED;
					}else if(argv[i].equals("-s")){//INCL SEQ
						seqflags = ChadoWriter.SEQINCL;
					}else if(argv[i].equals("-p")){//INCL Transposable Elements
						tpflags = ChadoWriter.TPINCL;
					}
				}else{
					if(infile==null){//FIRST IS INFILE
						infile = argv[i];
					}else if(outfile==null){//SECOND IS OUTFILE
						outfile = argv[i];
					}
				}
			}
		}

		ChadoWriter rd = new ChadoWriter(infile,outfile,parseflags,modeflags,seqflags,tpflags);
		rd.GameToChado();
	}
}


