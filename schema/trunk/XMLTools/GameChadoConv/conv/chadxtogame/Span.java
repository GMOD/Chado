//Span
package conv.chadxtogame;

import java.util.*;

public class Span {
private int m_start=0;
private int m_end=0;
private String m_src;

	public Span(String the_start,String the_end){
		try{
			m_start = Integer.decode(the_start).intValue();
		}catch(Exception ex){
			System.out.println("ERROR SPAN STR <"+the_start+">");
			ex.printStackTrace();
		}
		try{
			m_end = Integer.decode(the_end).intValue();
		}catch(Exception ex){
			System.out.println("ERROR SPAN STR <"+the_end+">");
			ex.printStackTrace();
		}
	}

	public Span(String the_start,String the_end,String the_src){
		this(the_start,the_end);
		m_src = the_src;
	}

	public Span(int the_start,int the_end){
		m_start = the_start;
		m_end = the_end;
	}

	public Span(int the_start,int the_end,String the_src){
		m_start = the_start;
		m_end = the_end;
		m_src = the_src;
	}

	public void setStart(int the_start){
		m_start = the_start;
	}

	public int getStart(){
		return m_start;
	}

	public int getEnd(){
		return m_end;
	}

	public void setSrc(String the_src){
		m_src = the_src;
	}

	public String getSrc(){
		return m_src;
	}

	public int getLength(){
		if(m_start<m_end){
			return (m_end-m_start+1);
		}else{
			return (m_start-m_end+1);
		}
	}

	public boolean isForward(){
		if(m_end>m_start){
			return true;
		}else{
			return false;
		}
	}

/*************************
	public boolean precedes(Span the_sp){
		if(the_sp==null){
			return false;
		}
		if((isForward())&&(the_sp.isForward())){
			System.out.print("FORWARD ");
			if(getStart()<the_sp.getStart()){
				System.out.println("EXON<"+toString()
					+"> PRECEDES <"+the_sp.toString()+">");
				return true;
			//}else if(getStart()==the_sp.getStart()){
			//	if(getEnd()<the_sp.getEnd()){
			//		return true;
			//	}
			}else{
				System.out.println("EXON<"+toString()
					+"> DNP <"+the_sp.toString()+">");
				return false;
			}
		}else if((!isForward())&&(!(the_sp.isForward()))){
			System.out.print("REVERSE ");
			if(getStart()>the_sp.getStart()){
				System.out.println("EXON<"+toString()
					+"> PRECEDES <"+the_sp.toString()+">");
				return true;
			}else{
				System.out.println("EXON<"+toString()
					+"> DNP <"+the_sp.toString()+">");
				return false;
			}
		}else if((isForward())&&(!(the_sp.isForward()))){
			System.out.println("FEATLOC PRECEDES() MIX1");
		}else if((!isForward())&&(the_sp.isForward())){
			System.out.println("FEATLOC PRECEDES() MIX2");
		}
		return false;
	}
*************************/

	public boolean precedes(Span the_sp,int strandi,int strandj){
		if(the_sp==null){
			return false;
		}
		if((strandi==1)&&(strandj==1)){
			//System.out.print("FORWARD ");
			if(getStart()<the_sp.getStart()){
				//System.out.println("EXON<"+toString()
				//	+"> PRECEDES <"+the_sp.toString()+">");
				return true;
			//}else if(getStart()==the_sp.getStart()){
			//	if(getEnd()<the_sp.getEnd()){
			//		return true;
			//	}
			}else{
				//System.out.println("EXON<"+toString()
				//	+"> DNP <"+the_sp.toString()+">");
				return false;
			}
		}else if((strandi==-1)&&(strandj==-1)){
			//System.out.print("REVERSE ");
			if(getStart()>the_sp.getStart()){
				//System.out.println("EXON<"+toString()
				//	+"> PRECEDES <"+the_sp.toString()+">");
				return true;
			}else{
				//System.out.println("EXON<"+toString()
				//	+"> DNP <"+the_sp.toString()+">");
				return false;
			}
		}else if((strandi==1)&&(strandj==-1)){
			System.out.println("FEATLOC PRECEDES() MIX1");
		}else if((strandi==-1)&&(strandj==1)){
			System.out.println("FEATLOC PRECEDES() MIX2");
		}
		return false;
	}

	public void grow(Span the_sp){
		if(the_sp==null){
			return;
		}
		if((m_start==0)&&(m_end==0)){ //FIRST ONE
			m_start = the_sp.getStart();
			m_end = the_sp.getEnd();
		}else{
			if(the_sp.isForward()){
				if(the_sp.getStart()<m_start){
					m_start = the_sp.getStart();
				}
				if(the_sp.getEnd()>m_end){
					m_end = the_sp.getEnd();
				}
			}else{
				if(the_sp.getStart()>m_start){
					m_start = the_sp.getStart();
				}
				if(the_sp.getEnd()<m_end){
					m_end = the_sp.getEnd();
				}
			}
		}
	}

	public String toString(){
		return (m_start+".."+m_end);
	}

	public Span advance(int the_amt){
		return (new Span((m_start+the_amt),(m_end+the_amt)));
	}

	public Span retreat(int the_amt){
		//System.out.println("RETREAT Span <"+toString()+">");
		Span sp = new Span((m_start-the_amt),(m_end-the_amt));
		//System.out.println("         TO  <"+sp.toString()+">");
		sp.setSrc(m_src);
		return sp;
	}

	public void Display(int the_depth){
		String offsetTxt = "";
		for(int i=0;i<the_depth;i++){
			offsetTxt += "\t";
		}
		System.out.println(offsetTxt+" Span <"+toString()+">");
	}
}



