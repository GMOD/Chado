//ATTRIB
package conv.gametochadx;

//FOR property, gene, dbxref,comment
import java.util.*;
public class Attrib {
private String m_AttribType;
private String m_type;
private String m_value;
private String m_name;
private String m_xref_db;
private String m_db_xref_id;
private String m_person;
private String m_date;
private String m_timestamp;
private String m_text;

	public Attrib(String the_AttribType){
		m_AttribType = the_AttribType;
	}

	public void setAttribType(String the_AttribType){
		m_AttribType = the_AttribType;
	}

	public String getAttribType(){
		return m_AttribType;
	}

	public void settype(String the_type){
		m_type = the_type;
	}

	public String gettype(){
		return m_type;
	}

	public void setvalue(String the_value){
		m_value = the_value;
	}

	public String getvalue(){
		return m_value;
	}

	public void setname(String the_name){
		m_name = the_name;
	}

	public String getname(){
		return m_name;
	}

	public void setxref_db(String the_xref_db){
		m_xref_db = the_xref_db;
	}

	public String getxref_db(){
		return m_xref_db;
	}

	public void setdb_xref_id(String the_db_xref_id){
		m_db_xref_id = the_db_xref_id;
	}

	public String getdb_xref_id(){
		return m_db_xref_id;
	}

	public void setperson(String the_person){
		m_person = the_person;
	}

	public String getperson(){
		return m_person;
	}

	public void setdate(String the_date){
		m_date = the_date;
	}

	public String getdate(){
		return m_date;
	}

	public void settimestamp(String the_timestamp){
		m_timestamp = the_timestamp;
	}

	public String gettimestamp(){
		return m_timestamp;
	}

	public void settext(String the_text){
		m_text = the_text;
	}

	public String gettext(){
		return m_text;
	}

	public void Display(int the_depth){
		String offsetTxt = "";
		for(int i=0;i<the_depth;i++){
			offsetTxt += "\t";
		}
		System.out.println(offsetTxt+"ATTR TYPE<"+m_AttribType+">");
		System.out.println(offsetTxt+"   TYPE    <"+m_type+">");
		System.out.println(offsetTxt+"   VALUE   <"+m_value+">");
		System.out.println(offsetTxt+"   NAME    <"+m_name+">");
		System.out.println(offsetTxt+"   XREF_DB <"+m_xref_db+">");
		System.out.println(offsetTxt+"   DB_XREF <"+m_db_xref_id+">");
		System.out.println(offsetTxt+"   PERSON  <"+m_person+">");
		System.out.println(offsetTxt+"   DATE    <"+m_date+">");
		System.out.println(offsetTxt+"   TIMESTMP<"+m_timestamp+">");
		System.out.println(offsetTxt+"   TEXT    <"+m_text+">");
	}
}

