//CurrTypeStack
package conv.chadxtogame;

import java.util.*;

public class CurrTypeStack implements Stack {

	public CurrTypeStack(){
		super();
	}
/*******************
	public static void Push(GenFeat the_element){
		if(m_GenFeatList!=null){
			m_GenFeatList.add(the_element);
		}
	}

	public static GenFeat Pop(){
		if((m_GenFeatList!=null)&&(m_GenFeatList.size()>0)){
			return (GenFeat)m_GenFeatList.remove(m_GenFeatList.size()-1);
		}else{
			return null;
		}
	}

	public static GenFeat Peek(){
		if((m_GenFeatList!=null)&&(m_GenFeatList.size()>0)){
			return (GenFeat)m_GenFeatList.get(m_GenFeatList.size()-1);
		}else{
			return null;
		}
	}

	public static int getDepth(){
		return m_GenFeatList.size();
	}

	public static void Display(){
		System.out.println("STACK:");
		for(int i=(m_GenFeatList.size()-1);i>=0;i--){
			GenFeat gf = (GenFeat)m_GenFeatList.get(i);
			System.out.println("  ["+i+"] ID<"+gf.getId()
					+"> TYPE<"+gf.getTypeId()+">");
		}
	}
*******************/
}

