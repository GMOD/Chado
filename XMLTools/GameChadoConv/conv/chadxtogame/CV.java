//CV
package conv.chadxtogame;

import java.util.*;

public class CV extends FeatSub {
private String m_cvname;

	public CV(String the_id){
		super(the_id);
	}

	public void setcvname(String the_cvname){
		m_cvname = the_cvname;
	}

	public String getcvname(){
		return m_cvname;
	}

	public void Display(int the_depth){
		String offsetTxt = "";
		for(int i=0;i<the_depth;i++){
			offsetTxt += "\t";
		}
		System.out.println(offsetTxt+"CV:");
		System.out.println(offsetTxt+"  ID        <"+m_Id+">");
		System.out.println(offsetTxt+"  cvname    <"+m_cvname+">");
	}
}

