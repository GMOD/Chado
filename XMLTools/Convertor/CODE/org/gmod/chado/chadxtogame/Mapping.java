//Mapping
package org.gmod.chado.chadxtogame;

import java.util.*;

public class Mapping {
private static HashMap m_AttribMap = new HashMap(10);

	public Mapping(){
	}

	public static void Add(String the_id,Attrib the_element){
		if(m_AttribMap!=null){
			m_AttribMap.put(the_id,the_element);
		}
	}

	public static Attrib Lookup(String the_id){
		if(m_AttribMap!=null){
			return (Attrib)(m_AttribMap.get(the_id));
		}else{
			return null;
		}
	}

	public static void Display(){
		System.out.println("MAPPED ATTRIBUTES:");
		Iterator it = m_AttribMap.keySet().iterator();
		while(it.hasNext()){
			String keyTxt = (String)it.next();
			System.out.println("  <"+keyTxt+">");
			Attrib at = Lookup(keyTxt);
			at.Display(1);
			System.out.println("");
		}
	}
}

