//DB
package conv.chadxtogame;

import java.util.*;

public class DB extends FeatSub {
private String m_dbname;

	public DB(String the_id){
		super(the_id);
	}

	public void setdbname(String the_dbname){
		m_dbname = the_dbname;
	}

	public String getdbname(){
		return m_dbname;
	}

	public void Display(int the_depth){
		String offsetTxt = "";
		for(int i=0;i<the_depth;i++){
			offsetTxt += "\t";
		}
		System.out.println(offsetTxt+"DB:");
		System.out.println(offsetTxt+"  ID        <"+m_Id+">");
		System.out.println(offsetTxt+"  dbname    <"+m_dbname+">");
	}
}

