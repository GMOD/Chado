//Ribosome.java
package conv.gametochadx;

import java.util.TreeMap;
import java.util.*;

/**
* Utility class to perform translations of nucleotide sequences into amino acid sequences.
*/ 
public class Ribosome {

public static int DEF_TRANS_TYPE = 0;
public static int MIT_TRANS_TYPE = 1;
public static int ALT_TRANS_TYPE = 2;

//public static String ENDSYMBOL = "@";
public static Character ENDSYMBOL = new Character('@');
public boolean m_isReadthrough = false;

	public Ribosome(){
	}

	public void setReadthrough(boolean the_isReadthrough){
		m_isReadthrough = the_isReadthrough;
	}

	public String getAminoAcid(String the_codon,int the_TransType){
		TreeMap CodonMap = null;
		if(the_TransType==DEF_TRANS_TYPE){
			CodonMap = makeDefaultCodonMap();
		}else if(the_TransType==MIT_TRANS_TYPE){
			CodonMap = makeMitCodonMap();
		}else if(the_TransType==ALT_TRANS_TYPE){
			CodonMap = makeAltCodonMap();
		}
		if(the_codon.length()==3){
			return (String)CodonMap.get(the_codon);
		}else{
			return null;
		}
	}

	public Vector getBasepairs(String the_AA,int the_TransType){
		Vector retVec = new Vector();
		TreeMap CodonMap = null;
		if(the_TransType==DEF_TRANS_TYPE){
			CodonMap = makeDefaultCodonMap();
		}else if(the_TransType==MIT_TRANS_TYPE){
			CodonMap = makeMitCodonMap();
		}else if(the_TransType==ALT_TRANS_TYPE){
			CodonMap = makeAltCodonMap();
		}

		Set ks = CodonMap.keySet();
		Iterator it = ks.iterator();
		String codonStr=null,aaStr=null;
		while(it.hasNext()){
			codonStr = (String)it.next();
			aaStr = (String)CodonMap.get(codonStr);
			if(aaStr.equals(the_AA)){
				retVec.add(codonStr);
			}
		}
		/*******
		Map sm = (Map)CodonMap.subMap(the_AA,the_AA);
		Collection col = sm.values();
		Iterator it = col.iterator();
		String bpStr = null;
		while(it.hasNext()){
			bpStr = (String)it.next();
			retVec.add(bpStr);
		}
		*******/
		return retVec;
	}

	//MAKE IT A STATIC MEMBER FUNCTION?
	public String translate(String the_Seq,int the_TransType){
		if(the_Seq==null){
			return null;
		}
		String tmpStr = new String(the_Seq);
		TreeMap CodonMap = null;
		if(the_TransType==DEF_TRANS_TYPE){
			CodonMap = makeDefaultCodonMap();
		}else if(the_TransType==MIT_TRANS_TYPE){
			CodonMap = makeMitCodonMap();
		}else if(the_TransType==ALT_TRANS_TYPE){
			CodonMap = makeAltCodonMap();
		}
		String ret = "";
		if(tmpStr!=null){
			tmpStr = tmpStr.toLowerCase();
			//System.out.println("TRANSLATING<"+tmpStr.substring(0,10)+">");
			while(tmpStr!=null){
				if(tmpStr.length()>=3){
					String the_Codon = tmpStr.substring(0,3);
					String token = (String)CodonMap.get(the_Codon);
					if(token==null){
						token="-";
						System.out.println("\tCONVERTED <"+the_Codon+"> TO <"+token+">");
					}
					if(token.equals(ENDSYMBOL.toString())){
						//System.out.println("\t\tEND SYM TMPSTR REMNDR IS<"+tmpStr+"> ENDSYM ADD");
						if(!m_isReadthrough){
							tmpStr = null;
						}
						ret += ENDSYMBOL.toString();
					}else{
						//System.out.println("\t\tNOT END SYM");
						ret += token;
						tmpStr = tmpStr.substring(3);
					}
				}else{
					//System.out.println("TMPSTR REMAINDER IS<"+tmpStr+">");
					tmpStr = null;
					//DONT ADD AN ENDSYMBOL IF IT MERELY RAN OUT OF SEQUENCE
					//ret += ENDSYMBOL.toString();
				}
			}
		}
		return ret;
	}

	public TreeMap makeDefaultCodonMap(){
		TreeMap DefMap = new TreeMap();
		DefMap.put("ttt","F");
		DefMap.put("ttc","F");
		DefMap.put("tta","L");
		DefMap.put("ttg","L");
		DefMap.put("tct","S");
		DefMap.put("tcc","S");
		DefMap.put("tca","S");
		DefMap.put("tcg","S");
		DefMap.put("tat","Y");
		DefMap.put("tac","Y");
		DefMap.put("taa",ENDSYMBOL.toString());
		DefMap.put("tag",ENDSYMBOL.toString());
		DefMap.put("tgt","C");
		DefMap.put("tgc","C");
		DefMap.put("tga",ENDSYMBOL.toString());
		DefMap.put("tgg","W");

		DefMap.put("ctt","L");
		DefMap.put("ctc","L");
		DefMap.put("cta","L");
		DefMap.put("ctg","L");
		DefMap.put("cct","P");
		DefMap.put("ccc","P");
		DefMap.put("cca","P");
		DefMap.put("ccg","P");
		DefMap.put("cat","H");
		DefMap.put("cac","H");
		DefMap.put("caa","Q");
		DefMap.put("cag","Q");
		DefMap.put("cgt","R");
		DefMap.put("cgc","R");
		DefMap.put("cga","R");
		DefMap.put("cgg","R");

		DefMap.put("att","I");
		DefMap.put("atc","I");
		DefMap.put("ata","I");
		DefMap.put("atg","M");	//START CODON
		DefMap.put("act","T");
		DefMap.put("acc","T");
		DefMap.put("aca","T");
		DefMap.put("acg","T");
		DefMap.put("aat","N");
		DefMap.put("aac","N");
		DefMap.put("aaa","K");
		DefMap.put("aag","K");
		DefMap.put("agt","S");
		DefMap.put("agc","S");
		DefMap.put("aga","R");
		DefMap.put("agg","R");

		DefMap.put("gtt","V");
		DefMap.put("gtc","V");
		DefMap.put("gta","V");
		DefMap.put("gtg","V");
		DefMap.put("gct","A");
		DefMap.put("gcc","A");
		DefMap.put("gca","A");
		DefMap.put("gcg","A");
		DefMap.put("gat","D");
		DefMap.put("gac","D");
		DefMap.put("gaa","E");
		DefMap.put("gag","E");
		DefMap.put("ggt","G");
		DefMap.put("ggc","G");
		DefMap.put("gga","G");
		DefMap.put("ggg","G");

		return DefMap;
	}

	public TreeMap makeMitCodonMap(){
		TreeMap MitMap = new TreeMap();
		MitMap.put("ttt","f");
		MitMap.put("ttc","f");
		MitMap.put("tta","l");
		MitMap.put("ttg","l");
		MitMap.put("tct","s");
		MitMap.put("tcc","s");
		MitMap.put("tca","s");
		MitMap.put("tcg","s");
		MitMap.put("tat","y");
		MitMap.put("tac","y");
		MitMap.put("taa",ENDSYMBOL.toString());
		MitMap.put("tag",ENDSYMBOL.toString());
		MitMap.put("tgt","c");
		MitMap.put("tgc","c");
		MitMap.put("tga",ENDSYMBOL.toString());
		MitMap.put("tgg","w");

		MitMap.put("ctt","l");
		MitMap.put("ctc","l");
		MitMap.put("cta","l");
		MitMap.put("ctg","l");
		MitMap.put("cct","p");
		MitMap.put("ccc","p");
		MitMap.put("cca","p");
		MitMap.put("ccg","p");
		MitMap.put("cat","h");
		MitMap.put("cac","h");
		MitMap.put("caa","q");
		MitMap.put("cag","q");
		MitMap.put("cgt","r");
		MitMap.put("cgc","r");
		MitMap.put("cga","r");
		MitMap.put("cgg","r");

		MitMap.put("att","i");
		MitMap.put("atc","i");
		MitMap.put("ata","i");
		MitMap.put("atg","m");
		MitMap.put("act","t");
		MitMap.put("acc","t");
		MitMap.put("aca","t");
		MitMap.put("acg","t");
		MitMap.put("aat","n");
		MitMap.put("aac","n");
		MitMap.put("aaa","k");
		MitMap.put("aag","k");
		MitMap.put("agt","s");
		MitMap.put("agc","s");
		MitMap.put("aga","r");
		MitMap.put("agg","r");

		MitMap.put("gtt","v");
		MitMap.put("gtc","v");
		MitMap.put("gta","v");
		MitMap.put("gtg","v");
		MitMap.put("gct","a");
		MitMap.put("gcc","a");
		MitMap.put("gca","a");
		MitMap.put("gcg","a");
		MitMap.put("gat","d");
		MitMap.put("gac","d");
		MitMap.put("gaa","e");
		MitMap.put("gag","e");
		MitMap.put("ggt","g");
		MitMap.put("ggc","g");
		MitMap.put("gga","g");
		MitMap.put("ggg","g");

		return MitMap;
	}

	public TreeMap makeAltCodonMap(){
		TreeMap AltMap = new TreeMap();
		AltMap.put("ttt","f");
		AltMap.put("ttc","f");
		AltMap.put("tta","l");
		AltMap.put("ttg","l");
		AltMap.put("tct","s");
		AltMap.put("tcc","s");
		AltMap.put("tca","s");
		AltMap.put("tcg","s");
		AltMap.put("tat","y");
		AltMap.put("tac","y");
		AltMap.put("taa",ENDSYMBOL.toString());
		AltMap.put("tag",ENDSYMBOL.toString());
		AltMap.put("tgt","c");
		AltMap.put("tgc","c");
		AltMap.put("tga",ENDSYMBOL.toString());
		AltMap.put("tgg","w");

		AltMap.put("ctt","l");
		AltMap.put("ctc","l");
		AltMap.put("cta","l");
		AltMap.put("ctg","l");
		AltMap.put("cct","p");
		AltMap.put("ccc","p");
		AltMap.put("cca","p");
		AltMap.put("ccg","p");
		AltMap.put("cat","h");
		AltMap.put("cac","h");
		AltMap.put("caa","q");
		AltMap.put("cag","q");
		AltMap.put("cgt","r");
		AltMap.put("cgc","r");
		AltMap.put("cga","r");
		AltMap.put("cgg","r");

		AltMap.put("att","i");
		AltMap.put("atc","i");
		AltMap.put("ata","i");
		AltMap.put("atg","m");
		AltMap.put("act","t");
		AltMap.put("acc","t");
		AltMap.put("aca","t");
		AltMap.put("acg","t");
		AltMap.put("aat","n");
		AltMap.put("aac","n");
		AltMap.put("aaa","k");
		AltMap.put("aag","k");
		AltMap.put("agt","s");
		AltMap.put("agc","s");
		AltMap.put("aga","r");
		AltMap.put("agg","r");

		AltMap.put("gtt","v");
		AltMap.put("gtc","v");
		AltMap.put("gta","v");
		AltMap.put("gtg","v");
		AltMap.put("gct","a");
		AltMap.put("gcc","a");
		AltMap.put("gca","a");
		AltMap.put("gcg","a");
		AltMap.put("gat","d");
		AltMap.put("gac","d");
		AltMap.put("gaa","e");
		AltMap.put("gag","e");
		AltMap.put("ggt","g");
		AltMap.put("ggc","g");
		AltMap.put("gga","g");
		AltMap.put("ggg","g");

		return AltMap;
	}

/**
* Simple test main().
*/
	public static void main(String args[]){
		Ribosome r = new Ribosome();
		String Seq = "ACTGACTGACTG";
		System.out.println("TRANSLATING <"+Seq+">");
		String protein = r.translate(Seq,Ribosome.DEF_TRANS_TYPE);
		System.out.println(protein);
	}
}


