//Pub
package conv.chadxtogame;

import java.util.*;

public class Pub extends FeatSub {

private String m_miniref;

	public Pub(String the_id){
		super(the_id);
	}

        public void setminiref(String the_miniref){
                m_miniref = the_miniref;
        }

        public String getminiref(){
                return m_miniref;
        }

	public void Display(int the_depth){
		String offsetTxt = "";
		for(int i=0;i<the_depth;i++){
			offsetTxt += "\t";
		}
		System.out.println(offsetTxt+"Pub:");
		System.out.println(offsetTxt+"  ID        <"+m_Id+">");
		System.out.println(offsetTxt+"  miniref   <"+m_miniref+">");
	}
}

