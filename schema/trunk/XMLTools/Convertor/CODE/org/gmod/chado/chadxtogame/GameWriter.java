//GameWriter.java
package org.gmod.chado.chadxtogame;

import java.io.*;

/****
//JAVA3
import com.sun.xml.tree.*;
import com.sun.xml.parser.Parser;
****/

/****/
//JAVA4
import javax.xml.parsers.*;
import javax.xml.transform.*;
import javax.xml.transform.stream.*;
import javax.xml.transform.dom.*;
/****/

import org.w3c.dom.*;
import org.xml.sax.*;

import java.util.*;

public class GameWriter {

private String m_InFile = null;
private String m_OutFile = null;
private Span m_NewREFSPAN = null;
private String m_NewREFSTRING = null;
private String m_OldREFSTRING = null;

//FOR BUILDING PREAMBLE
private HashSet m_CVList;
private HashSet m_CVTERMList;
private HashSet m_PUBList;
private HashSet m_EXONList;

private String m_ARMNAME = null;

String ANNORES_OFFSET = "\n      ";
String ANNORES_OFFSET_END = "\n    ";
String GAMERES_OFFSET = "\n          ";
String GAMERES_OFFSET_END = "\n        ";

	public GameWriter(String the_infile,String the_outfile,
			int the_DistStart,int the_DistEnd,
			String the_NewREFSTRING){
		if((the_infile==null)||(the_outfile==null)){
			System.exit(0);
		}
		m_InFile = the_infile;
		m_OutFile = the_outfile;
		m_NewREFSPAN = new Span(the_DistStart,the_DistEnd);
		m_NewREFSTRING = the_NewREFSTRING;
		System.out.println("START C->G INFILE<"+m_InFile
				+"> OUTFILE<"+m_OutFile
				+"> DIST<"+m_NewREFSPAN.toString()
				+"> NewREFSTRING<"+m_NewREFSTRING+">");
	}

	public void ChadoToGame(){
		ChadoSaxReader csr = new ChadoSaxReader();
		csr.parse(m_InFile);
		GenFeat TopNode = csr.getTopNode();
		writeFile(TopNode,m_OutFile);
		System.out.println("DONE C->G INFILE<"+m_InFile
				+"> OUTFILE<"+m_OutFile+">\n");
	}

	public void writeFile(GenFeat gf,String the_filePathName){
		try{
			/**************/
			//JAVA1.4
			DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
			factory.setValidating(true);
			factory.setIgnoringElementContentWhitespace(false);
			//factory.setCoalescing(true);
			DocumentBuilder builder = factory.newDocumentBuilder();
			DOMImplementation impl = builder.getDOMImplementation();
			Document m_DOC = impl.createDocument(null,"game",null);
			Element root = makeGameDoc(m_DOC,gf);

			DOMSource domSource = new DOMSource(m_DOC);
			StreamResult streamResult = new StreamResult(new FileWriter(the_filePathName));
			TransformerFactory transFactory = TransformerFactory.newInstance();
			Transformer trans = transFactory.newTransformer();
			trans.setOutputProperty(OutputKeys.ENCODING,"ISO-8859-1");
			trans.setOutputProperty(OutputKeys.INDENT,"yes");
			trans.setOutputProperty("{http://xml.apache.org/xslt}indent-amount","2");
			trans.transform(domSource,streamResult);
			/**************/
			/**************
			//JAVA1.3
			Document m_DOC = new Document();
			m_DOC.appendChild(makeGameDoc(m_DOC,gf));
			Writer out = new OutputStreamWriter(new FileOutputStream(the_filePathName,false));
			m_DOC.write(out);
			out.flush();
			**************/
		}catch(Exception ex){
			ex.printStackTrace();
		}
	}

	public Element makeGameDoc(Document the_DOC,GenFeat the_TopNode){
		Element root = the_DOC.getDocumentElement();

		//MAKE USE OF METADATA
		String mdARM=null,mdTITLE=null;
		String mdMIN=null,mdMAX=null,mdRESIDUES=null;
		System.out.println("READING METADATA");
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			GenFeat gf = the_TopNode.getGenFeat(i);
			if(gf instanceof Appdata){
				System.out.println("FOUND METADATA<"
						+gf.getId()+">");
				if(gf.getId().equals("arm")){
					mdARM = ((Appdata)gf).getText();
					System.out.println("ARM<"+mdARM+">");
				}else if(gf.getId().equals("title")){
					mdTITLE = ((Appdata)gf).getText();
					System.out.println("TITLE<"
						+mdTITLE+">");
				}else if(gf.getId().equals("min")){
					mdMIN = ((Appdata)gf).getText();
					System.out.println("MIN<"
						+mdMIN+">");
				}else if(gf.getId().equals("max")){
					mdMAX = ((Appdata)gf).getText();
					System.out.println("MAX<"
						+mdMAX+">");
				}else if(gf.getId().equals("residues")){
					mdRESIDUES = ((Appdata)gf).getText();
					System.out.println("RESIDUES LEN<"
						+mdRESIDUES.length()+">");
				}else{
				}
			}
		}
		System.out.println("DONE READING METADATA");


		String annotSeqName = null;
		if(mdTITLE!=null){
			System.out.println("RETREIVE ANNOT SEQ FROM METADATA");
			annotSeqName = mdTITLE;
			if((mdMIN!=null)&&(mdMAX!=null)){
				m_NewREFSPAN = new Span(mdMIN,mdMAX);
			}
			if(m_NewREFSTRING!=null){
				annotSeqName = m_NewREFSTRING;
			}
		}else{
			//ANNOT SEQUENCE GET INFO
			System.out.println("RETREIVE ANNOT SEQ INFO FROM FEAT");
			for(int i=0;i<the_TopNode.getGenFeatCount();i++){
				GenFeat gf = the_TopNode.getGenFeat(i);
				if((gf.getTypeId()!=null)&&(gf.getTypeId().startsWith("annot_sequence"))){
					if(m_NewREFSTRING!=null){
						annotSeqName = m_NewREFSTRING;
					}else{
						annotSeqName = gf.getId();
					}
				}
			}
			System.out.println("DONE RETREIVING ANNOT SEQ INFO");
		}

		System.out.println("START WRITING NON ANNOT SEQ FEAT FROM METADATA");
		root.appendChild(makeNonAnnotSeqFeatFromMetadata(the_DOC,
				annotSeqName,mdRESIDUES,"true"));

		System.out.println("START WRITING MAP POSITION");
		//MAP_POSITION
		if(mdARM!=null){
			root.appendChild(makeMapPos(the_DOC,
					annotSeqName,
					mdARM,
					new Span(mdMIN,mdMAX)));
			m_OldREFSTRING = annotSeqName;
		}else{
			for(int i=0;i<the_TopNode.getGenFeatCount();i++){
				GenFeat gf = the_TopNode.getGenFeat(i);
				if((gf.getTypeId()!=null)
						&&(gf.getTypeId().startsWith("arm"))){
					System.out.println("MAP_POS FEATURE<"
							+gf.getTypeId()+">");
					//gf.setSpan(m_NewREFSPAN);
					m_ARMNAME = gf.getUniqueName();
					root.appendChild(makeMapPos(the_DOC,
							annotSeqName,
							m_ARMNAME,
					//		gf.getSpan()));
							m_NewREFSPAN));
					m_OldREFSTRING = gf.getId();
				}
			}
		}
		//m_OldREFSTRING = annotSeqName;
		System.out.println("DONE WRITING MAP POSITION");

		System.out.println("START WRITING ANNOT & ANALYSIS FEATURES");
		System.out.println("CURR ANNOT NAME<"+annotSeqName
				+"> OLD<"+m_OldREFSTRING
				+"> NEW<"+m_NewREFSTRING+">");

		/*************************/
		//ANNOTATION, COMP_ANAL, SEQUENCE FEATURES
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			GenFeat gf = the_TopNode.getGenFeat(i);
			System.out.println("\nWRITING FEATURE <"+gf.getId()
					+"> OF TYPE<"+gf.getTypeId()+">");
			if((gf.getTypeId()!=null)&&(gf.getTypeId().startsWith("gene"))){
				root.appendChild(makeAnnotation(the_DOC,gf));
			}else if(gf.getProgram()!=null){
				root.appendChild(makeCompAnalysis(the_DOC,gf));
			}else if((gf.getTypeId()!=null)&&(gf.getTypeId().startsWith("sequence"))){
				root.appendChild(makeNonAnnotSeqFeat(the_DOC,gf,"false"));
			}else if((gf.getTypeId()!=null)
				&&((gf.getTypeId().startsWith("deleted_"))
				||(gf.getTypeId().startsWith("changed_")))){
				//HANDLED NEXT SO IT CAN BE LAST
			}else{
				System.out.println("\tNOT WRITTEN SINCE NO TYPE");
			}
		}
		System.out.println("DONE WRITING ANNOTATION AND ANALYSIS FEATURES");

		System.out.println("START WRITING DELETE FEATURES");
		//DELETE FEATURES
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			GenFeat gf = the_TopNode.getGenFeat(i);
			if((gf.getTypeId()!=null)
				&&((gf.getTypeId().startsWith("deleted_"))
				||(gf.getTypeId().startsWith("changed_")))){
					System.out.println("WRITING DELETE FEATURE <"+gf.getId()+"> OF TYPE<"+gf.getTypeId()+">");
					root.appendChild(
						makeModFeat(the_DOC,gf));
			}
		}
		/*************************/
		System.out.println("DONE WRITING DELETE FEATURES");
		System.out.println("VIEW MAPPING");
		Mapping.Display();
		return root;
	}

	public Element makeModFeat(Document the_DOC,GenFeat the_gf){
		//DEPENDS ON TYPE BEING CHECKED ABOVE
		Element modfeatNode = (Element)the_DOC.createElement(
				the_gf.getTypeId());
		String idStr = the_gf.getId();
		if(idStr!=null){
			int indx = idStr.indexOf(":");
			if(indx>0){
				idStr = idStr.substring(indx+1);
			}
			modfeatNode.setAttribute("id",idStr);
		}
		return modfeatNode;
	}

	public Element makeNonAnnotSeqFeatFromMetadata(Document the_DOC,
			String the_name,
			String the_residues,String the_focus){
		Element seqNode = (Element)the_DOC.createElement("seq");
		if(the_name!=null){
			seqNode.setAttribute("id",the_name);
		}
		if(the_residues!=null){
			seqNode.setAttribute("length",
					""+countLength(the_residues));
		}
		if((the_focus!=null)&&(the_focus.equals("true"))){
			seqNode.setAttribute("focus",the_focus);
		}
		if(the_name!=null){
			seqNode.appendChild(makeGenericNode(
					the_DOC,"name",the_name));
		}
		if(the_residues!=null){
			seqNode.appendChild(makeGenericNode(
					the_DOC,"residues",
					(ANNORES_OFFSET+the_residues
							+ANNORES_OFFSET_END)));
		}
		return seqNode;
	}

	public Element makeNonAnnotSeqFeat(Document the_DOC,
			GenFeat the_gf,String the_focus){
		Element seqNode = (Element)the_DOC.createElement("seq");
		seqNode.setAttribute("id",the_gf.getId());
		seqNode.setAttribute("length",
				""+countLength(the_gf.getResidues()));
		if(the_gf.getMd5()!=null){
			seqNode.setAttribute("md5checksum",the_gf.getMd5());
		}
		if((the_focus!=null)&&(the_focus.equals("true"))){
			seqNode.setAttribute("focus",the_focus);
		}
		if(the_gf.getName()!=null){
			seqNode.appendChild(makeGenericNode(
					the_DOC,"name",the_gf.getName()));
		}

		for(int i=0;i<the_gf.getFeatSubCount();i++){
			FeatSub fs = the_gf.getFeatSub(i);
			if(fs!=null){
				if(fs instanceof FeatProp){
					FeatProp fp = (FeatProp)fs;
				String pkey = fp.getPkeyId();
				if(pkey!=null){
					if(pkey.equals("description")){
						//Attrib TO HOLD GAME
						//<description>
						String pval = fp.getpval();
						seqNode.appendChild(
							makeGameTempStorage(
							the_DOC,pkey,pval));
					}
				}else{
					//Attrib TO HOLD NonAnnot <dbxref_id>
					seqNode.appendChild(makeFeatSubNode(
							the_DOC,fs));
				}
				}
			}
		}

		if(the_gf.getResidues()!=null){
			seqNode.appendChild(makeGenericNode(
					the_DOC,"residues",
					(ANNORES_OFFSET+the_gf.getResidues()
							+ANNORES_OFFSET_END)));
		}
		return seqNode;
	}

	public Element makeFeatSubNode(Document the_DOC,FeatSub the_attr){
		System.out.println("FEATSUB ID <"+the_attr.getId()+">");
		if(the_attr instanceof FeatProp){
			System.out.println("\tFeatProp");
		}else if(the_attr instanceof FeatDbxref){
			System.out.println("\tFeatDbxref");
		}else{
			System.out.println("\tUNKNOWN");
		}
		System.out.println("LLLLLRETURNINGNULL");
		return null;
	}


	public Element makeMapPos(Document the_DOC,
			String the_annotSeqName,
			String the_ARMname,
			Span the_span){
		Element mapPosNode = (Element)the_DOC.createElement("map_position");
		mapPosNode.setAttribute("type","tile");
		if(the_annotSeqName!=null){
			mapPosNode.setAttribute("seq",the_annotSeqName);
		}

		//ARM
		mapPosNode.appendChild(makeGenericNode(
					the_DOC,"arm",the_ARMname));

		if(the_span!=null){
			mapPosNode.appendChild(makeGameSpan(
					the_DOC,the_span));
		}
		return mapPosNode;
	}

	public Element makeAnnotation(Document the_DOC,GenFeat the_gf){
		System.out.println("START ANNOTATION");
		Element annotNode = (Element)the_DOC.createElement("annotation");
		if(the_gf.getId()!=null){
			annotNode.setAttribute("id",the_gf.getId());
			System.out.println("\tWRITING GAME ANNOT ID<"
					+the_gf.getId()+">");
		}
		if(the_gf.getName()!=null){
			annotNode.appendChild(makeGenericNode(
					the_DOC,"name",the_gf.getName()));
		}
		if(the_gf.getTypeId()!=null){
			annotNode.appendChild(makeGenericNode(
					the_DOC,"type",the_gf.getTypeId()));
		}

		//AUTHOR,PROPERTIES,COMMENTS
		makeAuthPropComm(annotNode,the_DOC,the_gf);

		//FEATURE_SET
		for(int i=0;i<the_gf.getGenFeatCount();i++){
			GenFeat gf = the_gf.getGenFeat(i);
			annotNode.appendChild(makeFeatureSet(the_DOC,gf));
		}
		System.out.println("END ANNOTATION");
		return annotNode;
	}

	public Element makeFeatureSet(Document the_DOC,GenFeat the_gf){
		System.out.println("START FEATURE_SET");
		Element featureSetNode = (Element)the_DOC.createElement("feature_set");
		//name,type,author,date,property
		featureSetNode.setAttribute("id",the_gf.getId());
		//PRODUCED SEQ HAS SAME NAME
		if(the_gf.getName()!=null){
			featureSetNode.setAttribute(
				"produces_seq",the_gf.getName());
		}
		//NAME
		if(the_gf.getName()!=null){
			featureSetNode.appendChild(makeGenericNode(
					the_DOC,"name",the_gf.getName()));
		}
		//TYPE
		if(the_gf.getTypeId()!=null){
			featureSetNode.appendChild(makeGenericNode(
					the_DOC,"type",the_gf.getTypeId()));
		}

		//AUTHOR,PROPERTIES,COMMENTS
		makeAuthPropComm(featureSetNode,the_DOC,the_gf);

		//SPAN
		for(int i=0;i<the_gf.getGenFeatCount();i++){
			GenFeat gf = the_gf.getGenFeat(i);
			if((gf.getTypeId()!=null)
					&&(!(gf.getTypeId().startsWith("aa")))){
				featureSetNode.appendChild(
						makeFeatureSpan(
						the_DOC,gf));
			}else{
				//DO LATER
			}
		}
		//SEQUENCE
		if(the_gf.getResidues()!=null){
			featureSetNode.appendChild(makeGameSeq(the_DOC,
					the_gf,the_gf.getUniqueName()));
		}
		//PROTEIN
		for(int i=0;i<the_gf.getGenFeatCount();i++){
			GenFeat gf = the_gf.getGenFeat(i);
			if((gf.getTypeId()!=null)
				&&(gf.getTypeId().startsWith("aa"))){
					featureSetNode.appendChild(
						makeGameSeq(the_DOC,gf,null));
			}
		}
		System.out.println("END FEATURE_SET");
		return featureSetNode;
	}

	public Element makeFeatureSpan(Document the_DOC,GenFeat the_gf){
		Element featureSpanNode = (Element)
				the_DOC.createElement("feature_span");
//YYYYY - NEED TO DIFFERENTIATE BETWEEN A SEQUENCE INSIDE A FEATURE_SET 
//AND A REGULAR FEATURE_SPAN (exon)
		//name,type,seq_relationship,span
		featureSpanNode.setAttribute("id",the_gf.getId());
		if(the_gf.getName()!=null){
			featureSpanNode.appendChild(makeGenericNode(
					the_DOC,"name",the_gf.getName()));
		}
		if(the_gf.getTypeId()!=null){
			featureSpanNode.appendChild(makeGenericNode(
					the_DOC,"type",the_gf.getTypeId()));
		}
		if((the_gf.getFeatLoc()!=null)
				&&(the_gf.getFeatLoc().getSpan()!=null)){
			Span sp = the_gf.getFeatLoc().getSpan().retreat(
					m_NewREFSPAN.getStart());
			featureSpanNode.appendChild(makeSeqRelNode(
					the_DOC,the_gf,sp));
		}
		return featureSpanNode;
	}


	public Element makeGameSeq(Document the_DOC,GenFeat the_gf,
			String the_altName){
		Element seqNode = (Element)the_DOC.createElement("seq");
		//ID
		if(the_altName!=null){
			seqNode.setAttribute("id",the_altName);
		}else if(the_gf.getName()!=null){
			seqNode.setAttribute("id",the_gf.getName());
		}
		//LENGTH
		seqNode.setAttribute("length",""+countLength(
				the_gf.getResidues()));
		//TYPE
		if(the_gf.getTypeId()!=null){
			if(the_gf.getTypeId().equals("transcript")){
				seqNode.setAttribute("type","cdna");
				//SINCE THIS SEQUENCE IS STORED AS A
				//RESIDUES OF A FEATURE
			}else if(the_gf.getTypeId().equals("mRNA")){
				seqNode.setAttribute("type","aa");
			}else{
				seqNode.setAttribute("type",the_gf.getTypeId());
			}
		}
		//MD5CHECKSUM
		if(the_gf.getMd5()!=null){
			seqNode.setAttribute("md5checksum",the_gf.getMd5());
		}

		//NAME
		if(the_altName!=null){
			seqNode.appendChild(makeGenericNode(
					the_DOC,"name",the_altName));
		}else if(the_gf.getName()!=null){
			seqNode.appendChild(makeGenericNode(
					the_DOC,"name",the_gf.getName()));
		}
		//RESIDUES
		seqNode.appendChild(makeGenericNode(
				the_DOC,"residues",
				(GAMERES_OFFSET+the_gf.getResidues()
						+GAMERES_OFFSET_END)));
		return seqNode;
	}

	public int countLength(String the_seq){
		if(the_seq!=null){
			int miscChar = 0;
			int len = the_seq.length();
			byte[] b = the_seq.getBytes();
			for(int i=0;i<len;i++){
				if((b[i]=='\n')||(b[i]==32)){
					miscChar++;
				}
			}
			return (len-miscChar);
		}
		return 0;
	}

	public void makeAuthPropComm(
			Element the_Node,Document the_DOC,GenFeat the_gf){
		//  AUTHOR,PROPERTIES,COMMENTS
		Vector propList = new Vector();
		Vector commentList = new Vector();
		Element authorNode = null;
		for(int i=0;i<((Feature)the_gf).getFeatSubCount();i++){
			FeatSub fs = ((Feature)the_gf).getFeatSub(i);
			if(fs instanceof FeatProp){
				FeatProp fp = (FeatProp)fs;
				if(fp.getPkeyId()==null){
					//DO NOTHING
				}else if(fp.getPkeyId().equals("comment")){
					commentList.add(
						makeGameFeatPropComment(
						the_DOC,fp));
				}else if(fp.getPkeyId().equals("author")){
					authorNode = makeGenericNode(the_DOC,
							"author",fp.getpval());
				}else{
					propList.add(
						makeGameFeatPropReg(the_DOC,fp));
				}
			}
		}

		//  AUTHOR
		if(authorNode!=null){
			the_Node.appendChild(authorNode);
		}

		//  DATE
		//if(the_gf.getDate()!=null){
		//	the_Node.appendChild(makeDateNode(
		//		the_DOC,the_gf.getDate(),the_gf.getDate());
		//}

		//  PROPERTIES
		for(int i=0;i<propList.size();i++){
			Element el = (Element)propList.get(i);
			the_Node.appendChild(el);
		}

		//  COMMENTS
		for(int i=0;i<commentList.size();i++){
			Element el = (Element)commentList.get(i);
			the_Node.appendChild(el);
		}

		//  DBXREF
		if(((Feature)the_gf).getDbxrefId()!=null){
			System.out.println("---DBXREF_ID");
			Dbxref d = ((Feature)the_gf).getDbxref();
			the_Node.appendChild(makeGameDbxref(the_DOC,
					d.getdbname(),
					d.getaccession()));
		}
		for(int i=0;i<((Feature)the_gf).getFeatDbxrefCount();i++){
			System.out.println("DBXREF_ID");
			FeatDbxref fd = (FeatDbxref)((Feature)the_gf)
					.getFeatDbxref(i);
			Dbxref d = fd.getDbxref();
			if(d!=null){
				the_Node.appendChild(makeGameDbxref(the_DOC,
						d.getdbname(),
						d.getaccession()));
			}
		}
	}

	public Element makeGenericNode(Document the_DOC,
			String the_type,String the_text){
		Element genericNode = (Element)the_DOC.createElement(the_type);
		genericNode.appendChild(the_DOC.createTextNode(the_text));
		return genericNode;
	}

	public Element makeGameTempStorage(Document the_DOC,
			String the_pkey,String the_pval){
		//FOR GAME NonAnnot 'seq' length when no <residues>
		Element descNode = (Element)the_DOC.createElement(the_pkey);
		descNode.appendChild(the_DOC.createTextNode(
				"\n  "+the_pval+"\n    "));
		return descNode;
	}

	public Element makeGameDbxref(Document the_DOC,
			String the_xref_dbTxt,String the_db_xref_idTxt){
		Element attrNode = (Element)the_DOC.createElement("dbxref");
		Element xref_dbNode = (Element)the_DOC.createElement("xref_db");
		xref_dbNode.appendChild(the_DOC.createTextNode(the_xref_dbTxt));
		attrNode.appendChild(xref_dbNode);
		Element db_xref_idNode = (Element)the_DOC.createElement("db_xref_id");
		db_xref_idNode.appendChild(the_DOC.createTextNode(the_db_xref_idTxt));
		attrNode.appendChild(db_xref_idNode);
		return attrNode;
	}

	public Element makeGameComment(Document the_DOC,
				String the_textTxt,
				String the_personTxt,
				String the_dateTxt,
				String the_timestampTxt){
		Element attrNode = (Element)the_DOC.createElement("comment");
		attrNode.setAttribute("internal","false");
		Element textNode = (Element)the_DOC.createElement("text");
		textNode.appendChild(the_DOC.createTextNode(
				"\n"+the_textTxt+"\n      "));
		attrNode.appendChild(textNode);
		Element personNode = (Element)the_DOC.createElement("person");
		personNode.appendChild(the_DOC.createTextNode(the_personTxt));
		attrNode.appendChild(personNode);
		if((the_timestampTxt!=null)&&(the_dateTxt!=null)){
			attrNode.appendChild(
				makeDateNode(the_DOC,
					the_timestampTxt,the_dateTxt));
		}
		return attrNode;
	}

	public Element makeDateNode(Document the_DOC,
			String the_timestamp,String the_date){
		Element dateNode = (Element)the_DOC.createElement("date");
		if(the_timestamp!=null){
			dateNode.setAttribute("timestamp",the_timestamp);
		}
		if(the_date!=null){
			dateNode.appendChild(the_DOC.createTextNode(the_date));
		}
		return dateNode;
	}

	public Element makeSeqRelNode(Document the_DOC,GenFeat the_gf,Span the_Span){
		//BECAUSE SOMETIMES ITS THE 'ALT' SPAN
		//SO NEED TO ACTUALLY PASS IN THE SPAN
		Element seqRelNode = (Element)the_DOC.createElement("seq_relationship");
		seqRelNode.setAttribute("type","query");
		/*************
		String SrcStr = null;
		if((the_gf!=null)&&(the_gf.getFeatLoc()!=null)
				&&(the_gf.getFeatLoc().getSrcFeatureId()!=null)){
			SrcStr = the_gf.getFeatLoc().getSrcFeatureId();
		}
		System.out.println("SRCSTR<"+m_NewREFSTRING
				+"> OLDREFSTR<"+m_OldREFSTRING+">");
		if((m_OldREFSTRING!=null)&&(SrcStr!=null)
				&&(SrcStr.equals(m_OldREFSTRING))){
			//System.out.println("OLDREFSTR<"+m_OldREFSTRING
			//		+"> SRC<"+SrcStr
			//		+"> SO BACKING OUT BY <"
			//		+m_NewREFSPAN.toString()+">");
			if(m_NewREFSTRING!=null){
				seqRelNode.setAttribute("seq",m_NewREFSTRING);
			}else{
				seqRelNode.setAttribute("seq","ARM-DUMMY");
			}
			if(m_NewREFSPAN!=null){
				the_Span = the_Span.retreat(m_NewREFSPAN.getStart());
			}
		}else{
			//System.out.println("OLDREFSTR<"+m_OldREFSTRING
			//		+"> SRC<"+SrcStr
			//		+"> SO NOT BACKING OUT");
			if(SrcStr!=null){
				seqRelNode.setAttribute("seq",SrcStr);
			}else{
				seqRelNode.setAttribute("seq","ARM");
			}
		}
		*************/
		/*************/
		seqRelNode.setAttribute("seq",m_OldREFSTRING);
		/*************/
		seqRelNode.appendChild(makeGameSpan(the_DOC,the_Span));
		return seqRelNode;
	}

	public Element makeCompAnalysis(Document the_DOC,GenFeat the_gf){
		Element compAnalNode = (Element)the_DOC.createElement("computational_analysis");
		compAnalNode.appendChild(makeDateNode(
				the_DOC,"TIMESTAMP","DATE_TEXT"));
		compAnalNode.appendChild(makeGenericNode(
				the_DOC,"program",the_gf.getProgram()));
		compAnalNode.appendChild(makeGenericNode(
				the_DOC,"database","DATABASE"));
		for(int i=0;i<the_gf.getGenFeatCount();i++){
			GenFeat gf = the_gf.getGenFeat(i);
			compAnalNode.appendChild(makeResultSet(the_DOC,gf));
		}
		return compAnalNode;
	}

	public Element makeResultSet(Document the_DOC,GenFeat the_gf){
		Element resultSetNode = (Element)the_DOC.createElement("result_set");
		resultSetNode.setAttribute("id",the_gf.getId());
		if(the_gf.getName()!=null){
			resultSetNode.appendChild(makeGenericNode(
					the_DOC,"name",the_gf.getName()));
		}
		for(int i=0;i<the_gf.getGenFeatCount();i++){
			GenFeat gf = the_gf.getGenFeat(i);
			resultSetNode.appendChild(makeResultSpan(the_DOC,gf));
		}
		return resultSetNode;
	}

	public Element makeResultSpan(Document the_DOC,GenFeat the_gf){
		Element resultSpanNode = (Element)the_DOC.createElement("result_span");
		resultSpanNode.setAttribute("id",the_gf.getId());
		if(the_gf.getTypeId()!=null){
			resultSpanNode.appendChild(makeGenericNode(
					the_DOC,"type",the_gf.getTypeId()));
		}
		if(the_gf.getrawscore()!=null){
			resultSpanNode.appendChild(makeGenericNode(
					the_DOC,"score",the_gf.getrawscore()));
			Element scoreOutputNode = (Element)the_DOC.createElement("output");
			scoreOutputNode.appendChild(makeGenericNode(
					the_DOC,"type","score"));
			scoreOutputNode.appendChild(makeGenericNode(
					the_DOC,"value",the_gf.getrawscore()));
			resultSpanNode.appendChild(scoreOutputNode);
		}

		/****************
		if(the_gf.getSpan()!=null){
			Span sp = the_gf.getSpan().retreat(m_NewREFSPAN.getStart());
			resultSpanNode.appendChild(makeSeqRelNode(
					the_DOC,the_gf,sp));
		}
		if(the_gf.getAltSpan()!=null){
			Span sp = the_gf.getAltSpan().retreat(m_NewREFSPAN.getStart());
			resultSpanNode.appendChild(makeSeqRelNode(
					the_DOC,the_gf,sp));
		}
		****************/
		/***************/
		if(the_gf.getFeatLoc()!=null){
			Span sp = the_gf.getFeatLoc().getSpan().retreat(m_NewREFSPAN.getStart());
			resultSpanNode.appendChild(makeSeqRelNode(
					the_DOC,the_gf,sp));
		}
		if(the_gf.getAltFeatLoc()!=null){
			Span sp = the_gf.getAltFeatLoc().getSpan().retreat(m_NewREFSPAN.getStart());
			resultSpanNode.appendChild(makeSeqRelNode(
					the_DOC,the_gf,sp));
		}
		/***************/
		return resultSpanNode;
	}

	public Element makeGameSpan(Document the_DOC,Span testSpan){
		Element gameSpanNode = (Element)the_DOC.createElement("span");
		gameSpanNode.appendChild(makeGenericNode(
				the_DOC,"start",(""+testSpan.getStart())));
		gameSpanNode.appendChild(makeGenericNode(
				the_DOC,"end",(""+testSpan.getEnd())));
		return gameSpanNode;
	}

	public Element makeGameFeatPropReg(Document the_DOC,FeatProp the_fp){
		String pkeyIdTxt = the_fp.getPkeyId();
		String pvalTxt = the_fp.getpval();
		if(pvalTxt.startsWith("SP:")){
			//System.out.println("STARTS WITH SP: <"+pvalTxt+">");
			//pkeyIdTxt = "protein_id";
			pvalTxt = pvalTxt.substring(3);
			//System.out.println("TRUNCATED TO <"+pvalTxt+">");
		}else if(pvalTxt.startsWith("GB:")){
			//pkeyIdTxt = "genbank_id";
			pvalTxt = pvalTxt.substring(3);
		}else if(pvalTxt.startsWith("FB:")){
			//pkeyIdTxt = "flybase_id";
			pvalTxt = pvalTxt.substring(3);
		}
		return makeGameProperty(the_DOC,pkeyIdTxt,pvalTxt);
	}

	public Element makeGameProperty(Document the_DOC,
			String the_typeTxt,String the_valueTxt){
		Element attrNode = (Element)the_DOC.createElement("property");
		Element typeNode = (Element)the_DOC.createElement("type");
		typeNode.appendChild(the_DOC.createTextNode(the_typeTxt));
		attrNode.appendChild(typeNode);
		Element valueNode = (Element)the_DOC.createElement("value");
		valueNode.appendChild(the_DOC.createTextNode(the_valueTxt));
		attrNode.appendChild(valueNode);
		return attrNode;
	}

	public Element makeGameFeatPropComment(Document the_DOC,
				FeatProp the_fp){
		String txtTxt = the_fp.getpval();
		String dateTxt = null;
		String tsTxt = null;
		if(txtTxt!=null){
			int indx = txtTxt.indexOf("::DATE:");
			if(indx>0){
				dateTxt = txtTxt.substring(indx+7);
				txtTxt = txtTxt.substring(0,indx);
			}
			if(dateTxt!=null){
				int dindx = dateTxt.indexOf("::TS:");
				if(dindx>0){
					tsTxt = dateTxt.substring(dindx+5);
					dateTxt = dateTxt.substring(0,dindx);
				}
			}
		}
		return makeGameComment(the_DOC,txtTxt,
				//the_fp.getpub_id(),
				the_fp.getPubId(),
				dateTxt,tsTxt);
	}

/**********************
	public Element makeGameFeatProp(Document the_DOC,FeatProp the_fp){
		if(the_fp.getPkeyId()==null){
			System.out.println("==========SHOULDNT BE NULL EITHER");
			return null;
		}else if(the_fp.getPkeyId().equals("comment")){
			String txtTxt = the_fp.getpval();
			String dateTxt = null;
			String tsTxt = null;
			if(txtTxt!=null){
				int indx = txtTxt.indexOf("::DATE:");
				if(indx>0){
					dateTxt = txtTxt.substring(indx+7);
					txtTxt = txtTxt.substring(0,indx);
				}
				if(dateTxt!=null){
					int dindx = dateTxt.indexOf("::TS:");
					if(dindx>0){
						tsTxt = dateTxt.substring(dindx+5);
						dateTxt = dateTxt.substring(0,dindx);
					}
				}
			}
			return makeGameComment(the_DOC,txtTxt,
					//the_fp.getpub_id(),
					the_fp.getPubId(),
					dateTxt,tsTxt);

		}else if(the_fp.getPkeyId().equals("author")){
			Element authNode = (Element)the_DOC.createElement("author");
			authNode.appendChild(the_DOC.createTextNode(
					the_fp.getpval()));
			return authNode;
		}else{
			String pkeyIdTxt = the_fp.getPkeyId();
			String pvalTxt = the_fp.getpval();
			if(pvalTxt.startsWith("SP:")){
				//System.out.println("STARTS WITH SP: <"+pvalTxt+">");
				//pkeyIdTxt = "protein_id";
				pvalTxt = pvalTxt.substring(3);
				//System.out.println("TRUNCATED TO <"+pvalTxt+">");
			}else if(pvalTxt.startsWith("GB:")){
				//pkeyIdTxt = "genbank_id";
				pvalTxt = pvalTxt.substring(3);
			}else if(pvalTxt.startsWith("FB:")){
				//pkeyIdTxt = "flybase_id";
				pvalTxt = pvalTxt.substring(3);
			}
			return makeGameProperty(the_DOC,pkeyIdTxt,pvalTxt);
		}
	}
**********************/
}
