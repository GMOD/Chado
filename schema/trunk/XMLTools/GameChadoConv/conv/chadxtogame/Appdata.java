//Appdata
package conv.chadxtogame;

import java.util.*;

//public class Appdata extends GenFeat {
public class Appdata extends FeatSub {
public String m_Text;

	public Appdata(String the_id){
		super(the_id);
	}

	public void setText(String the_Text){
		m_Text = the_Text;
	}

	public String getText(){
		return m_Text;
	}
}


