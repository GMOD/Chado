//SMTPTR

package conv.chadxtogame;

import java.util.*;
public class SMTPTR {
private String m_type;
private String m_key;
private FeatSub m_GF;

	public SMTPTR(String the_type){
		m_type = the_type;
	}

	public void setkey(String the_key){
		m_key = the_key;
	}

	public String getkey(){
		return m_key;
	}

	public void setGF(FeatSub the_GF){
		m_GF = the_GF;
		Mapping.Add(m_GF.getId(),m_GF);
	}

	public FeatSub getGF(){
		return m_GF;
	}

	public FeatSub getFeatSub(){
		if(m_GF!=null){
			return m_GF;
		}else if(m_key!=null){
			//LOOK UP THE APPROPRIATE CVTERM,
			//RETURN ITS VALUE
			//System.out.println("getFeatSub FOR <"+m_key+">");
			FeatSub gf = Mapping.Lookup(m_key);
			//if(gf==null){
			//	System.out.println("BUT IS NULL");
			//}
			return gf;
		}else{
			//System.out.println("SMTPTR TOTALLY NULL!");
			return null;
		}
	}

	public String getValue(){
		//System.out.print("CALLING getValue() TYPE<"
		//		+m_type+"> KEY<"+m_key+"> RET<");
		FeatSub gf = getFeatSub();
		String retStr = "";
		if(m_type==null){
			return retStr;
		}

		if(gf!=null){
			if(m_type.equals("type")){
				retStr = ((CVTerm)gf).getname();
			}else if(m_type.equals("pkey")){
				retStr = ((CVTerm)gf).getname();
			}else if(m_type.equals("dbxref")){
				//retStr = ((Dbxref)gf).getgenus();
			}else if(m_type.equals("pub")){
				retStr = ((Pub)gf).getminiref();
			}else if(m_type.equals("cv")){
				retStr = ((CV)gf).getcvname();
			}else if(m_type.equals("db")){
				retStr = ((DB)gf).getdbname();
			//}else if(m_type.equals("feature")){
			//	retStr = ((Feature)gf).getId();
			}else{//ORGANISM,PUB,DBXREF
				retStr = "SOME_GENFEAT_VALUE";
			}
		}else{
			retStr = m_key;
		}

		//System.out.println(retStr+">");
		return retStr;
	}

	public FeatSub getObjValue(){
		FeatSub gf = getFeatSub();
		if(gf!=null){
			return gf;
		}else{
			System.out.println("DONE BEEN EMPTY<"+m_type+">");
			return null;
		}
	}

	public void Display(int the_depth){
		String offsetTxt = "";
		for(int i=0;i<the_depth;i++){
			offsetTxt += "\t";
		}
		System.out.println(offsetTxt+"SMTPTR TYPE <"+m_type+">");
		System.out.println(offsetTxt+"   TEXT <"+m_key+">");
		if(m_GF!=null){
			m_GF.Display(the_depth+1);
		}
		System.out.println(offsetTxt+"END SMTPTR TYPE");
	}
}

