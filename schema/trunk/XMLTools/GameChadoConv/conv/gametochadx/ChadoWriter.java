//ChadoWriter
package conv.gametochadx;
import java.io.*;
//import conv.util.*;

//JAVA4 HAS an XML parser built in, and it works differently than the
//one used with JAVA3
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

public class ChadoWriter {

public static int WRITEALL = 0;
public static int WRITECHANGED = 1;

public static int SEQOMIT = 0;
public static int SEQINCL = 1;
public static int TPINCL = 0;
public static int TPOMIT = 1;

private String m_NewREFSTRING = "";
private String m_OldREFSTRING = null;
private Span m_REFSPAN = new Span(1,1);

private String m_InFile = null;
private String m_InFileName = null;
private String m_OutFile = null;
private int m_parseflags = GameSaxReader.PARSEALL;
private int m_modeflags = WRITEALL;
private int m_seqflags = 0;
private int m_tpflags = TPOMIT;

//FOR BUILDING PREAMBLE
private HashSet m_CVList;
private HashSet m_CVTERMList;
private HashSet m_PUBList;
private HashSet m_EXONList;
private HashSet m_DBList;

private int m_ExonCount = 0;
private Vector m_ExonList = null;
private Vector m_RenExonList = null;
private String m_ExonGeneName = null;
private Vector m_TranUNList = null;
private Vector m_ProtUNList = null;

//private boolean testForward = true;

	public ChadoWriter(String the_infile,String the_outfile,
			int the_parseflags,int the_modeflags,
			int the_seqflags,int the_tpflags){
		m_parseflags = the_parseflags;
		m_modeflags = the_modeflags;
		m_seqflags = the_seqflags;
		m_tpflags = the_tpflags;
		if(the_infile==null){
			//System.out.println("NO INPUT FILE");
			System.exit(0);
		}
		m_InFile = the_infile;
		int indx = m_InFile.lastIndexOf("/");
		if(indx>0){
			m_InFileName = m_InFile.substring(indx+1);
		}
		m_OutFile = the_outfile;
		if(m_OutFile!=null){
			//OMIT OUTPUT FILE IN COMMAND LINE IN ORDER TO
			//FIND OUT WHICH GAME VERSION PRODUCED THE INPUT FILE
			String ver = GameVersionReader.getVerString(m_InFile);
			System.out.println("\nFILE<"+m_InFileName+"> VER<"+ver+">");
			//System.out.println("START G->C INFILE<"+m_InFile
			//		+"> OUTFILE<"+m_OutFile
			//		+"> FLAG<"+m_parseflags+">");
		}
	}

	public void GameToChado(){
		//READ GAME FILE
		GameSaxReader gsr = new GameSaxReader();
		gsr.parse(m_InFile,m_parseflags);
		GenFeat TopNode = gsr.getTopNode();
		//System.out.println("DONE PARSING GAME FILE");
		//WRITE CHADO FILE
		writeFile(TopNode,m_OutFile);
		//TopNode.Display(0);
		if(m_OutFile!=null){
			//System.out.println("DONE G->C INFILE<"+m_InFile
			//		+"> OUTFILE<"+m_OutFile+">\n");
		}
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
			Document m_DOC = impl.createDocument(null,"chado",null);
			Element root = makeChadoDoc(m_DOC,gf);

			DOMSource domSource = new DOMSource(m_DOC);
			StreamResult streamResult = null;
			if(the_filePathName!=null){
				streamResult = new StreamResult(new FileWriter(the_filePathName));
			}else{
				streamResult = new StreamResult(System.out);
			}
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
			m_DOC.appendChild(makeChadoDoc(m_DOC,gf));
			Writer out = new OutputStreamWriter(new FileOutputStream(the_filePathName,false));
			m_DOC.write(out);
			out.flush();
			**************/
		}catch(Exception ex){
			ex.printStackTrace();
		}
	}

	//TOP NODE
	public Element makeChadoDoc(Document the_DOC,GenFeat the_TopNode){
		Element root = the_DOC.getDocumentElement();

		//PREAMBLE
		//SOME OF THE CVTERMS ARE HARDCODED
		storeCV("chromosome_arm","SO");
		storeCV("gene","SO");
		storeCV("mRNA","SO");
		storeCV("exon","SO");
		storeCV("tRNA","SO");
		storeCV("match","SO");
		storeCV("protein","SO");
		storeCV("start_codon","SO");
		storePUB("Gadfly","curator");
		storeCV("partof","relationship type");
		storeCV("producedby","relationship type");
		storeCV("transposable_element","SO");
		storeCV("element","SO");


		//CHANGED AND DELETED FEATURES
		Vector chngdGeneList = new Vector();
		Vector delGeneList = new Vector();
		Vector delTranList = new Vector();

		boolean hasTransaction = false;
		if(m_modeflags==WRITECHANGED){
			//HANDLE changed_gene,deleted_gene,deleted_transcript
			//SORT THEM OUT AND SAVE FOR CREATION LATER
			for(int i=0;i<the_TopNode.getGenFeatCount();i++){
				GenFeat gf = the_TopNode.getGenFeat(i);
				if(gf instanceof ModFeat){
					if(gf.getType().startsWith("changed_gene")){
						//System.out.println("MARK GENE<"+gf.getId()+"> AS CHANGED");
						chngdGeneList.add(gf);
					}else if(gf.getType().startsWith("deleted_gene")){
						//System.out.println("MARK GENE<"+gf.getId()+"> AS DELETED");
						delGeneList.add(gf);
					}else if(gf.getType().startsWith("deleted_transcript")){
						//System.out.println("MARK TRANSCRIPT <"+gf.getId()+"> AS DELETED");
						delTranList.add(gf);
					}else{
						System.out.println("PROBLEM - WHAT COULD THIS BE???");
					}
				}
			}

			//PROCESS LIST TO REMOVE INSERTS/DELETES IN SAME FILE
			//CHECK THE 'CHANGED' LIST TO SEE IF IT WAS
			//SUBSEQUENTLY DELETED IN THIS SAME FILE, IN WHICH
			//CASE UNMARK THE CHANGED GENE AS CHANGED
			GenFeat delF=null,chngdF=null;
			if(delGeneList.size()>0){
				hasTransaction = true;
			}
			if(chngdGeneList.size()>0){
				hasTransaction = true;
			}
			for(int i=0;i<delGeneList.size();i++){
				delF = (GenFeat)delGeneList.get(i);
				for(int j=0;j<chngdGeneList.size();j++){
					chngdF = (GenFeat)chngdGeneList.get(j);
					if(delF.getId().equals(chngdF.getId())){
						chngdGeneList.remove(j);
					}
				}
			}

			//MARK ALL GENES WHICH HAVE BEEN LISTED AS CHANGED
			//AND GET ITS LIST OF NON ANNOT SEQUENCES
			//(FROM ITS 'produces_seq' TAG)
			//NEED TO MARK ALL NON ANNOT SEQUENCES WHICH ARE
			//IN THE ABOVE prodSeqList VECTOR, KEEP THESE
			//AND THROW AWAY THE REST
			Vector prodSeqList = new Vector();
			for(int i=0;i<chngdGeneList.size();i++){
				GenFeat gf = (GenFeat)chngdGeneList.get(i);
				//System.out.println("CHANGED GENE<"+gf.getId()+">");
				prodSeqList.addAll(markGeneAsChanged(
						the_TopNode,gf.getId(),
						delTranList));
			}
			for(int i=0;i<the_TopNode.getGenFeatCount();i++){
				GenFeat gf = the_TopNode.getGenFeat(i);
				if(gf instanceof Seq){
					if(prodSeqList.contains(gf.getId())){
						//System.out.println("NEEDED SEQ<"+gf.getId()+">");
						gf.setChanged(true);
					}
				}
			}

			//SEE IF ANY DELETED TRANSCRIPTS ARE IN ANY
			//OF THE CHANGED GENES
			for(int i=0;i<chngdGeneList.size();i++){
				GenFeat gf = (GenFeat)chngdGeneList.get(i);
				String geneId = gf.getId();
				//System.out.println("CHANGED GENE<"+geneId+">");
				if((geneId!=null)&&(geneId.indexOf("temp")<0)){
					for(int j=0;j<delTranList.size();j++){
						GenFeat gft = (GenFeat)delTranList.get(j);
						String transId = gft.getId();
						if((transId!=null)&&(transId.startsWith(geneId))){
							delTransFromGene(the_TopNode,transId,geneId);
							//System.out.println("\tDELETED TRANS<"+transId+"> FROM INSIDE GENE<"+geneId+">");
						}
					}
				}
			}
		}

		if((m_modeflags==WRITECHANGED)&&(hasTransaction==false)){
			//System.out.println("\tNO TRANSACTIONS");
			System.exit(0);
		}

		//DO A PASS THROUGH THE WHOLE DATAMODEL, PICKING OUT
		//CVTERMS WHICH NEED TO BE DECLARED
		preprocessCVTerms(the_TopNode);

		//METADATA (map_position feature written below)
		if(the_TopNode.getArm()!=null){
			m_NewREFSTRING = the_TopNode.getArm();
			if(the_TopNode.getSpan()!=null){
				m_REFSPAN = the_TopNode.getSpan();
			}else{
				m_REFSPAN = new Span(1,1);
			}
		}
		//System.out.println("REFSPAN<"+m_REFSPAN+">");

		//FIND NON ANNOT SEQ WITH FOCUS 'true' TO GET OLD REF STRING
		String tmpResidues = null;
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			GenFeat gf = the_TopNode.getGenFeat(i);
			if(gf instanceof Seq){
				if((gf.getFocus()!=null)&&(gf.getFocus().equals("true"))){
					m_OldREFSTRING = gf.getId();
					tmpResidues = gf.getResidues();
				}
			}
		}

		if(m_NewREFSTRING!=null){
			int indx = m_NewREFSTRING.indexOf(".");
			if(indx>0){
				m_NewREFSTRING = m_NewREFSTRING.substring(0,indx);
			}
		}

		if(m_OldREFSTRING!=null){
			root.appendChild(makeAppdata(
					the_DOC,"arm",m_NewREFSTRING));
		}
		if(m_OldREFSTRING!=null){
			root.appendChild(makeAppdata(
					the_DOC,"title",m_OldREFSTRING));
		}
		if(m_REFSPAN!=null){
			root.appendChild(makeAppdata(
					the_DOC,"fmin",(""+(m_REFSPAN.getStart()))));
			root.appendChild(makeAppdata(
					the_DOC,"fmax",(""+m_REFSPAN.getEnd())));
		}
		if(tmpResidues!=null){
			tmpResidues = cleanString(tmpResidues);
			root.appendChild(makeAppdata(
					the_DOC,"residues",tmpResidues));
		}

		root = makePreamble(the_DOC,root);

		//FIND THE REFERENCE SEQUENCE FROM THE GAME FILE
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			GenFeat gf = the_TopNode.getGenFeat(i);
			if(gf instanceof Seq){
				if((gf.getFocus()!=null)
					&&(gf.getFocus().equals("true"))){
					//INSTEAD, WE SHOULD WRITE AN
					// _appdata FOR 'TITLE' and 'RESIDUES'
					m_OldREFSTRING = gf.getId();
				}
			}
		}

//ARM
	//REFERENCE FEATURE
		//ONLY ONE MAP_POSTION PER GAME FILE, REGARDLESS
		//OF HOW MANY ANNOTATIONS ARE THERE
		root.appendChild(makeArmNode(the_DOC,m_NewREFSTRING));

	//DELETE GENE FEATURES
		for(int i=0;i<delGeneList.size();i++){
			GenFeat gf = (GenFeat)delGeneList.get(i);
			if(gf.getId().indexOf(":temp")<=0){//NOT A 'TEMP'
				//System.out.println("MAKE DELETE FOR<"+gf.getId()+">");
				root.appendChild(makeDelFeat(the_DOC,gf));
			}
		}
	//DELETE TRANSCRIPT FEATURES
		for(int i=0;i<delTranList.size();i++){
			GenFeat gf = (GenFeat)delTranList.get(i);
			if(gf.getId().indexOf(":temp")<=0){//NOT A 'TEMP'
				//System.out.println("MAKE DELETE FOR<"
				//		+gf.getId()+">");
				root.appendChild(makeDelFeat(the_DOC,gf));
			}
		}

	//ANNOTATIONS, COMP_ANAL, AND NON ANNOT SEQUENCES
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			GenFeat gf = the_TopNode.getGenFeat(i);
			if(gf instanceof Annot){
				if((gf.isChanged())||(m_modeflags==WRITEALL)){
					if(isvalidIdTYPE(gf.getId())){
						Element anNode = makeAnnotNode(the_DOC,gf);
						if(anNode!=null){
							root.appendChild(anNode);
						}
					}
				}
			}else if(gf instanceof ComputationalAnalysis){
				if(m_OutFile!=null){
					//System.out.println("WRITING COMP_ANALYSIS<"+gf.getId()+">");
				}
				root.appendChild(makeAnalysisNode(the_DOC,gf));
			}else if((gf instanceof Seq)){//&&(m_seqflags==SEQINCL)){
				//IGNORE
			}else if(gf instanceof ModFeat){
				//DONE EARLIER
			}else{
				if(m_OutFile!=null){
					System.out.println("PROBLEM - SOME UNKNOWN FEAT TYPE<"+gf.getId()+">\n");
				}
			}
		}
		return root;
	}

	public void delTransFromGene(GenFeat the_TopNode,
			String the_transId,String the_geneId){
		//System.out.println("START delTransFromGene");
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			GenFeat gene = the_TopNode.getGenFeat(i);
			if(gene instanceof Annot){
			//System.out.println("TESTING GENE<"+gene.getId()
			//		+"> TO SEE IF IT IS<"+the_geneId+">");
			if((gene.getId()!=null)
					&&(gene.getId().equals(the_geneId))){
					//System.out.println("\tTESTING <"
					//		+gene.getGenFeatCount()
					//		+"> TRANSCRIPTS");
				for(int j=0;j<gene.getGenFeatCount();j++){
					GenFeat tran = gene.getGenFeat(j);
					//System.out.println("\t\tTRANS ID<"
					//		+tran.getId()
					//		+"> NAME<"
					//		+tran.getName()
					//		+"> TO SEE IF IT IS<"
					//		+the_transId+">");
					if((tran.getId().equals(the_transId))								||((tran.getName()!=null)&&(tran.getName().equals(the_transId)))){
						//System.out.println("\t\t\tFOUND AND READY TO DELETE");
						gene.delGenFeat(j);
						return;
					}
				}
			}
			}
		}
		//System.out.println("END delTransFromGene");
	}

	public Vector markGeneAsChanged(GenFeat topNode,String the_id,
			Vector the_delTranList){
		//RETURNS A LIST OF ALL NON ANNOT SEQUENCES
		//	REFERENCED IN THIS GENE
		Vector prodSeqList = new Vector();
		for(int i=0;i<topNode.getGenFeatCount();i++){
			GenFeat gf = topNode.getGenFeat(i);
			if(gf.getType()!=null){
				//System.out.println("\tCHECKING GENE TYPE<"
				//		+gf.getType()+"> WITH ID<"
				//		+gf.getId()+">");
				if(gf.getId().equals(the_id)){
					//System.out.println("\t\tSETTING GENE<"
					//		+the_id+"> TO TRUE");
					gf.setChanged(true);
					prodSeqList = gf.getProducedSequenceList();
				}
				/*************/
				//IF THE ID IS FOR ONE OF ITS TRANSCRPTS
				for(int j=0;j<gf.getGenFeatCount();j++){
					GenFeat tgf = gf.getGenFeat(j);
					if((tgf.getId()!=null)&&(tgf.getId().equals(the_id))){
						tgf.setChanged(true);
						prodSeqList.addAll(tgf.getProducedSequenceList());
					}
				}
				/*************/
				//FIGURE OUT IF IT WAS A TRANSCRIPT DELETION
				//FOR A 'temp' TRANSCRIPT
				for(int j=0;j<the_delTranList.size();j++){
					GenFeat dt = (GenFeat)the_delTranList.get(j);
					if(dt.getId().indexOf(":temp")>0){
						//SEE IF THIS temp transcript
						//IS IN THIS GENE, IF SO MARK IT
						for(int k=0;k<gf.getGenFeatCount();k++){
							GenFeat gft = (GenFeat)gf.getGenFeat(k);
							if((gft.getId()!=null)&&(gft.getId().equals(dt.getId()))){
								
								gf.delGenFeat(k);
							}
						}
					}
				}
			}else{
				//System.out.println("\tCHECKING GENE <"
				//		+gf.getId()+"> WITH NULL TYPE");
			}
		}
		return prodSeqList;
	}

	public Element makeAppdata(Document the_DOC,
			String the_name,String the_data){
		Element appdataNode = (Element)the_DOC.createElement("_appdata");
		appdataNode.setAttribute("name",the_name);
		appdataNode.appendChild(the_DOC.createTextNode(the_data));
		return appdataNode;
	}

	public Element makeArmNode(Document the_DOC,String the_ArmSTRING){
		Element RefFeatNode = (Element)the_DOC.createElement("feature");

		//ID
		RefFeatNode.setAttribute("id",the_ArmSTRING);

		//UNIQUENAME
		RefFeatNode.appendChild(makeGenericNode(
					the_DOC,"uniquename",the_ArmSTRING));

		//ORGANISM_ID
		RefFeatNode.appendChild(makeGenericNode(
					the_DOC,"organism_id","Dmel"));

		//TYPE_ID
		RefFeatNode.appendChild(makeGenericNode(
					the_DOC,"type_id","chromosome_arm"));
		return RefFeatNode;
	}

	public Element makeAnnotNode(Document the_DOC,GenFeat gf){
		//DONT PROCESS TE's FOR NOW
		if((m_tpflags==ChadoWriter.TPOMIT)
				&&(gf.getId()!=null)
				&&(gf.getId().startsWith("TE"))){
			return null;
		}

		boolean changeTransForPseudo = false;
		if((gf.getType()!=null)&&(gf.getType().startsWith("pseudo"))){
			gf.setType("gene");
			changeTransForPseudo = true;
		}

		for(int i=0;i<gf.getGenFeatCount();i++){
			GenFeat tran = gf.getGenFeat(i);
			for(int j=0;j<gf.getGenFeatCount();j++){
				GenFeat tranj = gf.getGenFeat(j);
			}
		}

	//PREPROCESS THIS ANNOTATION
		//CALCULATE FEATLOC's FOR TRANSCRIPT AND GENES FROM EXONS
		//ALSO, CREATE A LIST OF ALL KNOWN EXON SPANS SO THAT THEY
		//CAN BE RENAMED TO BE IN ORDER AND REUSE THE SAME NAME FOR
		//THE SAME SPAN ACROSS ALL TRANSCRIPTS FOR A GIVEN GENE
		m_ExonList = new Vector();
		m_RenExonList = new Vector();
		m_TranUNList = new Vector();
		m_ProtUNList = new Vector();
		Span geneSpan = null;
		//System.out.println("\nCALCULATING UNION FOR<"+gf.getId()+">");
		m_ExonGeneName = gf.getId();
		//System.out.println("\nGENE_NAME<"+m_ExonGeneName+">");

		for(int i=0;i<gf.getGenFeatCount();i++){
			GenFeat tran = gf.getGenFeat(i);
			if(tran instanceof FeatureSet){
			if(tran.getType()==null){
				tran.setType("mRNA");
			}
			if(changeTransForPseudo){
				tran.setType("pseudogene");
			}
			//System.out.print("FOR<"+gf.getId()+"> TRAN type <"
			//		+tran.getType()+"> CONV TO<");
		

			//tran.setType(convertTYPE(tran.getType()));
			if((gf.getId()!=null)&&(!(gf.getId().startsWith("CR")))){
				tran.setType(convertTYPE(tran.getType()));
			}

			//System.out.println(tran.getType()+">");
	
			
			if(((gf.getId()!=null)&&(gf.getId().startsWith("CR")))
					||(isvalidTransTYPE(tran.getType()))){
				Span tranSpan = null;
				Span protSpan = null;
				for(int j=0;j<tran.getGenFeatCount();j++){
					GenFeat exon = tran.getGenFeat(j);
					if(exon instanceof FeatureSpan){

					//COMPENSATE FOR MISSING OR OLD
					//EXON TYPES
					if(exon.getType()==null){
						exon.setType("exon");
					}else if(exon.getType().equals("start_codon")){
					}else if(exon.getType().equals("exon")){
					}else if(exon.getType().startsWith("translate")){
						exon.setType("start_codon");
					}else{//SOME ODD TYPE
						//System.out.println("CONVERTING EXON TYPE <"+exon.getType()+"> TO <exon> FOR ID<"+exon.getId()+">");
						exon.setType("exon");
					}

					//CALCULATE THE SPANS AND BUILD
					//EXON LIST FOR ORDERING UPON PRINTING 
					if(exon.getType().startsWith("start_codon")){
						protSpan = exon.getSpan();
						Span tmpSpan = protSpan;
						//System.out.println("PROT_SPAN<"+protSpan.toString()+">");
						//System.out.println("REF_SPAN<"+m_REFSPAN.toString()+">");
						protSpan = protSpan.advance(m_REFSPAN.getStart()-1);
						//System.out.println("===ADVANCING ID<"
						//	+exon.getId()
						//	+">\tSP<"+tmpSpan
						//	+">\tTO<"+protSpan+">");
						protSpan.setSrc(m_NewREFSTRING);
						exon.setSpan(protSpan);
					}else if(exon.getType().equals("exon")){
						Span exonSpan = exon.getSpan();
						Span tmpSpan = exonSpan;
						exonSpan = exonSpan.advance(m_REFSPAN.getStart()-1);
						//System.out.println("ADVANCING ID<"
						//	+exon.getId()
						//	+">\tSP<"+tmpSpan
						//	+">\tTO<"+exonSpan+">");
						exonSpan.setSrc(m_NewREFSTRING);
						exon.setSpan(exonSpan);

						String re = getRenExonName(exonSpan);
						//System.out.println("NAMED<"+re+">");
						if(re==null){
							m_RenExonList.add(
								new RenEx(
								exon.getName(),
								exonSpan));
						}

						if(tranSpan==null){
							tranSpan=exonSpan;
						}else{
							tranSpan = tranSpan.union(
								exonSpan);
						}
						//System.out.println("AS ADVANCED EXON SPAN<"+exonSpan.toString()+">");
					}else{
						System.out.println("\tUNK FEATURE_SPAN TYPE<"+exon.getType()+">");
					}
					}
				}
				if(tranSpan!=null){
					tranSpan.setSrc(m_NewREFSTRING);
					tran.setSpan(tranSpan);
					if(geneSpan==null){//FIRST TRANSCRIPT
						geneSpan = tranSpan;
					}else{//ADD SUBSEQUENT TRANS RANGES
						geneSpan = geneSpan.union(
								tranSpan);
					}
				}
			}
			}
		}
		if(geneSpan!=null){
			geneSpan.setSrc(m_NewREFSTRING);
		}
		gf.setSpan(geneSpan);

		Span annotSpan = gf.getSpan();
		//ADJUST FOR 0,1 OFFSET
		//CANT DO retreat() AGAIN, AS IT ALSO CONVERTS COORDINATE
		//SYSTEMS INSTEAD OF MERELY ADJUSTING LATERALLY
		Span scaffoldSpan = new Span((m_REFSPAN.getStart()-1),
				(m_REFSPAN.getEnd()));
		//ABOVE TO COMPENSATE FOR INTERBASE COORDS
		if(scaffoldSpan.contains(annotSpan)){
			//System.out.println("\n===WRITING ANNOT <"
			//		+gf.getId()+"> IN<"+m_InFileName+">");
			//THIS ANNOTATION IS CONTAINED WITHIN THE SCAFFOLD
			//SO IT SHOULD BE PROCESSED
			//System.out.println("\tANNOT START<"
			//		+annotSpan.getStart()
			//		+"> END<"+annotSpan.getEnd()+">");
			//System.out.println("\tSCAFF START<"
			//		+scaffoldSpan.getStart()
			//		+"> END<"+scaffoldSpan.getEnd()+">");
		}else{
			//THIS ANNOTATION IS NOT FULLY CONTAINED WITHIN
			//THE SCAFFOLD, SO IT SHOULD BE IGNORED
			//System.out.println("\n===IGNORING ANNOT <"
			//		+gf.getId()+"> IN<"+m_InFileName+">");
			//System.out.println("\tANNOT START<"
			//		+annotSpan.getStart()
			//		+"> END<"+annotSpan.getEnd()+">");
			//System.out.println("\tSCAFF START<"
			//		+scaffoldSpan.getStart()
			//		+"> END<"+scaffoldSpan.getEnd()+">");
			return null;
		}

		for(int x=0;x<m_RenExonList.size();x++){
			RenEx rex = (RenEx)m_RenExonList.get(x);
			for(int y=0;y<m_RenExonList.size();y++){
				RenEx rey = (RenEx)m_RenExonList.get(y);
				if((x!=y)&&(rex.getName()!=null)&&(rey.getName()!=null)&&(rex.getName().equals(rey.getName()))){
					System.out.println("CONFLICT BETWEEN<"+rex+"> AND<"+rey+">");
				}
			}
		}

	//WRITE OUT THIS ANNOTATION
		//System.out.println("START ANNOT NODE");
		Element GeneFeatNode = (Element)the_DOC.createElement("feature");
		//HEADER
		GeneFeatNode = makeFeatHeader(the_DOC,gf,GeneFeatNode,
				null,null,null);
		//ASPECT
		for(int j=0;j<gf.getGenFeatCount();j++){
			GenFeat agf = gf.getGenFeat(j);
			if(agf instanceof Aspect){
				//System.out.println("\tWRITING ASPECT");
				GeneFeatNode.appendChild(
					makeFeatCVTerm(the_DOC,(Aspect)agf));
			}
		}

		//System.out.print("ANNOTATION TYPE<"+gf.getType()+">");
		gf.setType(convertTYPE(gf.getType()));
		//System.out.println("CONVERTED TO <"+gf.getType()+">");
		if((gf.getType()!=null)&&(gf.getType().equals("remark"))){
			//IGNORE TRANSCRIPTS AND EXONS
			//System.out.println("REMARKS ONLY WRITTEN");
			return GeneFeatNode;
		}


		//System.out.println("START FILL_IN_BLANK_NAMES");
		fillInBlankNames(m_ExonGeneName);
		//System.out.println("END FILL_IN_BLANK_NAMES");

		//FEATURE_SET
		for(int j=0;j<gf.getGenFeatCount();j++){
			GenFeat fsgf = gf.getGenFeat(j);
			if(fsgf instanceof FeatureSet){
			if(((gf.getId()!=null)&&(gf.getId().startsWith("CR")))
					||(isvalidTransTYPE(fsgf.getType()))){
			//if(isvalidTransTYPE(fsgf.getType())){
				m_ExonCount = 0;
				GeneFeatNode.appendChild(
						makeFeatRel(the_DOC,"partof",0,
						makeFeatBodyNode(the_DOC,fsgf,
								null,
								gf.getType(),
								gf.getId())));
				//System.out.println("\tWROTE FEATURE_SET");
			}
			}
		}
		//System.out.println("DONE ANNOT NODE");
		//DisplayRenExon();
		return GeneFeatNode;
	}

	public Element makeSeqNode(Document the_DOC,
			GenFeat the_gf,Span firstSpan,
			String the_parentName,String the_parentId){
		String seqType = the_gf.getType();

		Element seqFeatNode = (Element)the_DOC.createElement("feature");

		//ATTRIBUTES
		String seqId = the_gf.getId();
		seqId = textReplace(seqId,".3","");
		String seqName = the_gf.getName();
		seqName = textReplace(seqName,".3","");
		if(seqId==null){
			seqId = seqName;
		}

		String parentBase = getBase(the_parentName);

		if((parentBase!=null)
				&&(seqId!=null)
				&&(seqId.startsWith(parentBase))){
			if(seqType.equals("aa")){
				//System.out.print("TEXTREPLACE<"+seqId);
				seqId = textReplace(seqId,"-R","-P");
				textCheck(seqId);
				//System.out.println("> WITH<"+seqId+">");
			}
		}

		//ID
		if(seqId!=null){
			int dashSeq = seqId.indexOf("_seq");
			if(dashSeq>0){
				seqId = seqId.substring(0,dashSeq);
			}
			seqFeatNode.setAttribute("id",seqId);
		}

		//System.out.println("\tPROTEIN ID<"+seqId
		//+"> OF TRANSCRIPT ID<"+the_parentId
		//+"> NAME<"+the_parentName+">\n");
		//NAME
		//IS THIS USEFUL???
		if((the_parentName!=null)
				&&(seqName!=null)
				&&(seqName.startsWith(the_parentName))){
			if((seqType.equals("aa"))||(seqType.equals("protein"))){
				seqName = textReplace(seqName,"-R","-P");
				textCheck(seqName);
			}
		}

		//System.out.println("PROT SEQ_NAME<"+seqName+">");
		if(seqName!=null){
			if((seqType.equals("aa"))||(seqType.equals("protein"))){
				seqName = textReplace(seqName,"-R","-P");
				textCheck(seqName);
				//System.out.println("  SEQNAME1<"+seqName
				//		+"> PAR<"+the_parentName+">");
				if((the_parentName!=null)&&(seqName.indexOf("temp")>0)){
					//seqName = getBase(the_parentName)
					//	+getProtSuffix(seqName);
					/**/
					seqName = textReplace(the_parentName,"-R","-P");
					/**/

					//System.out.println("  SEQNAME2<"+seqName+">");
				}
			}
			seqFeatNode.appendChild(makeGenericNode(
					the_DOC,"name",seqName));
			//System.out.println("PROTEIN ID<"+seqId
			//		+"> NAME<"+seqName+">\n");
		}

		//CHECK FOR MULTIPLE PROTEINS WITH SAME UNIQUENAME
		if(seqName!=null){
			if((seqType.equals("aa"))||(seqType.equals("protein"))){
			//System.out.println("SAVING PROTEIN<"+seqName+">");
			for(int u=0;u<m_ProtUNList.size();u++){
				String oldun = (String)m_ProtUNList.get(u);
				if(oldun.equals(seqName)){
					System.out.println("ERROR: PROT UNIQUENAME<"
							+seqName+"> IS REPEATED");
				}
			}
			m_ProtUNList.add(seqName);
			}
		}


		//UNIQUENAME
		String uniquename = seqName;
		if(uniquename==null){
			uniquename = seqId;
		}

		if(uniquename==null){
			uniquename = "UNKNOWN";
		}
		if((seqType.equals("aa"))||(seqType.equals("protein"))){
			uniquename = textReplace(uniquename,"-R","-P");
			textCheck(uniquename);
		}
		seqFeatNode.appendChild(makeGenericNode(
				the_DOC,"uniquename",uniquename));


		//ORGANISM_ID
		seqFeatNode.appendChild(makeGenericNode(
				the_DOC,"organism_id","Dmel"));

		//MD5CHECKSUM
		if(the_gf.getMd5()!=null){
			seqFeatNode.appendChild(makeGenericNode(
					the_DOC,"md5checksum",the_gf.getMd5()));
		}

		//TYPE_ID
		if(seqType!=null){
				seqFeatNode.appendChild(makeGenericNode(
						the_DOC,"type_id",
						convertTYPE(seqType)));
		}

		//SEQLEN
		if(the_gf.getResidueLength()!=null){
			seqFeatNode.appendChild(makeGenericNode(
					the_DOC,"seqlen",the_gf.getResidueLength()));
		}else{
			seqFeatNode.appendChild(makeGenericNode(
					the_DOC,"seqlen","0"));
		}

		//RESIDUES
		if(the_gf.getResidues()!=null){
			String tmpRes = cleanString(
					the_gf.getResidues());
			seqFeatNode.appendChild(makeGenericNode(
					the_DOC,"residues",tmpRes));
		}

		/*******************
		if(seqType.equals("aa")){
			//System.out.println("PROTEIN WITH GIVEN SEQLEN<"
			//	+the_gf.getResidueLength()+">"); 
			if(the_gf.getResidues()!=null){
				//System.out.println("PROTEIN WITH GIVEN SEQ OF LEN<"
				//	+the_gf.getResidues().length()+">"); 
				//System.out.println("PROTEIN WITH GIVEN SEQUENCE<"
				//	+the_gf.getResidues()+">");
			}
		}
		*******************/

		//DBXREF_ID
		if((seqType!=null)&&((seqType.equals("gene"))
				||(isvalidTransTYPE(seqType)))){
			if(isvalidIdTYPE(the_gf.getId())){
				seqFeatNode.appendChild(
						makeDbxrefIdAttrNode(
						the_DOC,"Gadfly",
						the_gf.getId()));
			}
		}

		//FEATURE_DBXREF
		//System.out.println("FEATURE_DBXREF");
		for(int i=0;i<the_gf.getAttribCount();i++){
			Attrib attr = the_gf.getAttrib(i);
			if(attr!=null){
				if(attr.getAttribType().equals("dbxref")){
					seqFeatNode.appendChild(
						makeFeatureDbxrefAttrNode(
						the_DOC,attr));
				}else{
					//System.out.println("\tATTR_TYPE<"
					//	+attr.getAttribType()+">");
				}
			}
		}

		//SPANS
		if(firstSpan!=null){
			seqFeatNode.appendChild(makeFeatureLoc(
					the_DOC,firstSpan,true));
		}
		//System.out.println("END NON_ANNOT_SEQ NODE");
		return seqFeatNode;
	}

	public String textReplace(String the_str,String the_old,
			String the_new){
		if((the_str==null)||(the_old==null)
				||(the_new==null)){
			return null;
		}
		int indx = the_str.lastIndexOf(the_old);
		if(indx>=0){
			String firstPart = the_str.substring(0,indx);
			String lastPart = the_str.substring(
					indx+the_old.length());
			return firstPart+the_new+lastPart;
		}
		return the_str;
	}

	public void textCheck(String the_str){
		if(the_str!=null){
			int resp = 0;
			int strlen = the_str.length();
			int indx = the_str.lastIndexOf("-R");
			if((indx>0)&&((indx+2)<strlen)){
				String suffix = the_str.substring(indx+2,indx+3);
				//System.out.println("SUFFIX<"+suffix+">");
				/********/
				try{
					resp = Integer.decode(suffix).intValue();
				}catch(Exception ex){
				}
				if(resp>0){
					System.out.println("WARNING: SUFFIX FOR <"
							+the_str+"> IS A NUMBER");
				}
				/********/
			}
			indx = the_str.lastIndexOf("-P");
			if((indx>0)&&((indx+2)<strlen)){
				String suffix = the_str.substring(indx+2,indx+3);
				//System.out.println("SUFFIX<"+suffix+">");
				/********/
				try{
					resp = Integer.decode(suffix).intValue();
				}catch(Exception ex){
				}
				if(resp>0){
					System.out.println("WARNING: SUFFIX FOR <"
							+the_str+"> IS A NUMBER");
				}
				/********/
			}
		}
	}

	public String baseName(String the_name){
		if(the_name==null){
			return null;
		}
		int indx = the_name.lastIndexOf("-R");
		if(indx>=0){
			String firstPart = the_name.substring(0,indx);
			return firstPart;
		}
		return the_name;
	}

	public Element makeDelFeat(Document the_DOC,GenFeat the_gf){
		//System.out.println("MOD FEAT<"+the_gf.getId()+">\n");
		Element modfeatNode = (Element)the_DOC.createElement("feature");
		modfeatNode.setAttribute("op","delete");

		//ID
		if(the_gf.getId()!=null){
			modfeatNode.setAttribute("ref","Gadfly:"+the_gf.getId());
		}
		return modfeatNode;
	}


	public Element makeFeatCVTerm(Document the_DOC,Aspect the_gf){
		Element featureCVTerm = (Element)
				the_DOC.createElement("feature_cvterm");
		Element CVTermId = (Element)the_DOC.createElement("cvterm_id");
		Element CVTerm = (Element)the_DOC.createElement("cvterm");
		for(int i=0;i<the_gf.getAttribCount();i++){
			Attrib attr = the_gf.getAttrib(i);
			if(attr!=null){
				if(attr.getAttribType().equals("dbxref")){
					if(attr.getdb_xref_id().startsWith("GO:")){
						CVTerm.setAttribute("id",attr.getdb_xref_id());
						break;//EXPECT THERE TO BE ONLY ONE
					}
				}
			}
		}

		Element CVId = (Element)the_DOC.createElement("cv_id");
		Element termname = (Element)the_DOC.createElement("name");
		if(the_gf.getFunction()!=null){
			CVId.appendChild(the_DOC.createTextNode("molecular_function"));
			termname.appendChild(the_DOC.createTextNode(the_gf.getFunction()));
		}else{//cellular process,biological component
		}
		CVTerm.appendChild(CVId);
		CVTerm.appendChild(termname);

		CVTermId.appendChild(CVTerm);
		featureCVTerm.appendChild(CVTermId);
		//PUB
		featureCVTerm.appendChild(makeGenericNode(
				the_DOC,"pub_id","gadfly3"));
		return featureCVTerm;
	}

	public Element makeFeatRel(Document the_DOC,
			String the_relType,int the_rank,Element the_el){
		//FEATURE_RELATIONSHIP WRAPPER
		Element featrel = (Element)the_DOC.createElement(
				"feature_relationship");
		if(the_rank>0){
			featrel.appendChild(makeGenericNode(
					the_DOC,"rank",(""+the_rank)));
		}
		featrel.appendChild(makeGenericNode(
				the_DOC,"type_id",the_relType));

		Element subjfeat = (Element)the_DOC.createElement("subject_id");
		subjfeat.appendChild(the_el);
		featrel.appendChild(subjfeat);
		return featrel;
	}

	public Element makeFeatBodyNode(Document the_DOC,GenFeat the_gf,
			String the_parentName,String the_parentType,
			String the_parentId){
		Element FeatNode = (Element)the_DOC.createElement("feature");
		FeatNode = makeFeatHeader(the_DOC,the_gf,FeatNode,
				the_parentName,the_parentType,the_parentId);
		Span startCodonSpan = null;
		//Span transSpan = null;
		//if(the_gf instanceof FeatureSet){
		//	transSpan = the_gf.getSpan();
			//if((transSpan!=null)&&(the_gf.getId()!=null)){
			//	transSpan.setSrc(the_gf.getId());
			//}
		//}
		if((the_gf.getType()!=null)&&(the_gf.getType().equals("remark"))){
			//IGNORE EXONS AND PROTEINS OF THIS TRANSCRIPT
			System.out.println("REMARKS SHOW ONLY HEADER INFO, REST IGNORED");
			return FeatNode;
		}
		String calcaaStr = null;

		Vector ExonList = new Vector();
		int newExonNum = 0;
		for(int i=0;i<the_gf.getGenFeatCount();i++){
			GenFeat gf = the_gf.getGenFeat(i);
			if(gf instanceof FeatureSet){
				FeatNode.appendChild(
						makeFeatRel(the_DOC,"partof",0,
						makeFeatBodyNode(the_DOC,gf,
						the_gf.getName(),
						the_gf.getType(),
						the_gf.getId())));
			System.out.println("\n");
			}else if(gf instanceof FeatureSpan){
				if(gf.getType()==null){
					System.out.println("NULLTYPE ID<"+gf.getId()+">");
					//NO TYPE GIVEN FOR SPAN - GUESS
					if(the_gf.getType().equals("transposable_element")){
						//PARENT IS TYPE 'TE'
						gf.setType(the_gf.getType());
					}else if((gf.getId()!=null)
						&&(gf.getId().startsWith("TE"))){
						//PARENT IS TYPE 'TE' BY NAME
						gf.setType("transposable_element");
					}else if(isvalidTransTYPE(the_gf.getType())){
						//PARENT IS transcript
						//EITHER exon OR start_codon
						if(gf.getSpan().getLength()==3){
							gf.setType("start_codon");
							System.out.println("BAD");
						}else{
							gf.setType("exon");
						}
					}else{
						gf.setType("exon");
					}
					System.out.println("\tISNOW<"+gf.getType()+">");
				}

				if(gf.getType().equals("start_codon")){
					startCodonSpan = gf.getSpan();
					//System.out.println("\n================");
					//System.out.println("NEW_STARTCODON<"+
					//	startCodonSpan+">");
					newExonNum = 0;
	
				}else if(gf.getType().equals("exon")){
					String newExonName = getRenExonName(
							gf.getSpan());
					//System.out.println("\tEXON NEWNAME<"
					//	+newExonName
					//	+"> SPAN<"+gf.getSpan()+">");
					newExonNum++;

					gf.setId(newExonName);
					gf.setName(newExonName);
					FeatNode.appendChild(
						makeFeatRel(the_DOC,"partof",
						newExonNum,
						makeFeatBodyNode(the_DOC,gf,
						the_gf.getName(),
						the_gf.getType(),
						the_gf.getId())));
					ExonList.add(gf.getSpan());
				}else{
//NOMI APOLLO BUG
				}
			}else if(gf instanceof Seq){
				if(gf.getType()==null){
					//GUESS AT TYPE
					if(gf.getResidues()!=null){
						String res = gf.getResidues().substring(0,1);
						//System.out.println("SAMPLERES<"
						//	+res+">");
						if(res.equals("A")
							||res.equals("C")
							||res.equals("G")
							||res.equals("T")
							||res.equals("a")
							||res.equals("c")
							||res.equals("g")
							||res.equals("t")){
							gf.setType("cdna");
						}else{
							gf.setType("aa");
						}
			
					}
				}

				if(gf.getType().equals("cdna")){
					//NEEDS   startCodonSpan,ExonList,gf
					//RETURNS cdnaStr,calcaaStr
					String cdnaStr = cleanString(
							gf.getResidues());
					System.out.println("\nCALC PROTEIN FOR FEATURE_SET ID<"+the_gf.getId()+"> TYPE<"+the_gf.getType()+">");
					//CALCULATE PROTEIN
					if((cdnaStr!=null)
						&&(the_gf.getId()!=null)
						&&(!(the_gf.getId().startsWith("CR")))
						&&(gf.getId()!=null)
						&&(!(gf.getId().startsWith("CR")))){
						int st = 0;
						if(startCodonSpan!=null){
							st = calcRelSCPos(
								startCodonSpan,
								ExonList);
							//System.out.println("TRANSCRIPT <"+the_gf.getId()+"> HAS A START CODON OF<"+startCodonSpan+"> AND CALC START<"+st+">");
						}else{
							//FIND FIRST ATG
							st = cdnaStr.indexOf("ATG");
							startCodonSpan = calcStartCodon(cdnaStr,ExonList);
							System.out.println("WARNING:TRANSCRIPT <"+the_gf.getId()+"> NO START CODON SO CALC AS <"+startCodonSpan+"> AND START CALC <"+st+">");
								
						}
						if(st<0){
							System.out.println("PROBLEM FOR <"+the_gf.getId()+"> CDNA<"+cdnaStr+">");
						}else{
						cdnaStr = cdnaStr.substring(st);
						Ribosome r = new Ribosome();
						calcaaStr = r.translate(cdnaStr,
							Ribosome.DEF_TRANS_TYPE);
						GenFeat protGF = new GenFeat(null);
						protGF.setType("aa");
						protGF.setSpan(startCodonSpan);
						String protId = textReplace(gf.getId(),"-R","-P");
						//System.out.println("PROT_ID<"+protId+"> OLD<"+gf.getId()+">");
						textCheck(protId);
						protGF.setId(protId);
						protGF.setName(protId);
						calcaaStr = cleanProt(calcaaStr);
						calcaaStr = cleanString(calcaaStr);
						//System.out.println("COMPUTED PROTEIN<"
						//		+calcaaStr+">");
						if(calcaaStr!=null){
							protGF.setResidues(calcaaStr);
							protGF.setResidueLength(""+calcaaStr.length());
						}
						Span newSpan = ProtCalc.calcNewProtSpan(
								protGF.getSpan(),
								calcaaStr.length(),
								ExonList);
						newSpan.setSrc(m_NewREFSTRING);
						FeatNode.appendChild(
						makeFeatRel(the_DOC,"producedby",0,
							makeSeqNode(the_DOC,
								protGF,newSpan,
								the_gf.getName(),
								the_gf.getId())));
						}
					}else{
						System.out.println("\nPROTEIN NOT COMPUTED FOR <"+the_gf.getId()+"> StartCodon <"+startCodonSpan+"> FEATURE_SET TYPE<"+the_gf.getType()+">");
						if((the_gf.getType()!=null)&&(the_gf.getType().equals("mRNA"))){
							System.out.println("WARNING: SHOULD HAVE BEEN A PROTEIN COMPUTED");
						}
						if(cdnaStr!=null){
							System.out.println("CDNASTR HAS LEN<"+cdnaStr.length()+">");
						}else{
							System.out.println("CDNASTR IS NULL");
						}
					}
				}else if(gf.getType().equals("aa")){
					String givenaaStr= cleanString(
							gf.getResidues());
					if(calcaaStr!=null){
					int cmp = calcaaStr.compareTo(givenaaStr);
					if(cmp!=0){
						System.out.println("CALCULATED PROTEIN DIFFERS FROM GIVEN PROTEIN IN feature_set<"+the_gf.getId()+">");
						System.out.println("GIVEN PROTEIN<"
								+givenaaStr+">");
						if(givenaaStr!=null){
							System.out.println("LEN<"+givenaaStr.length()+">\n");
						}
						System.out.println("CALC PROTEIN<"
								+calcaaStr+">");
						if(calcaaStr!=null){
							System.out.println("LEN<"+calcaaStr.length()+">\n");
						}
					}
					}
					//System.out.println("PROTCOMPARE<"+cmp+">");
				}else{
					System.out.println("SHOULDNOTSEE UNK TYPE<"+gf.getType()+">");
				}
			}else{//COMP_ANAL/RESULT_SET/SPAN
				System.out.println("SHOULD NEVER SEE THIS??");
				FeatNode.appendChild((Element)
					the_DOC.createElement("analysis"));
			}
		}
		//System.out.println("PTB");
		return FeatNode;
	}

	private String cleanProt(String the_prot){
		if(the_prot!=null){
			int indx = the_prot.indexOf("@");
			if(indx>0){
				the_prot = the_prot.substring(0,indx);
			}
		}
		return the_prot;
	}

	private boolean isForward(Vector the_spanList){
		boolean forw = true;
		if((the_spanList!=null)&&(the_spanList.size()>0)){
			Span ex = (Span)the_spanList.get(0);
			if(ex.getStart()>ex.getEnd()){
				forw = false;
			}
		}
		return forw;
	}

	private Span calcStartCodon(String the_cdnaStr,Vector the_spanList){
		//System.out.println("CALC_START_CODON");
		boolean isForward = true;
		Span sc = null;
		if((the_spanList!=null)&&(the_spanList.size()>0)){
			Span ex = (Span)the_spanList.get(0);
			if(ex.getStart()>ex.getEnd()){
				isForward = false;
			}
			sc = ex;
		}
		int start = the_cdnaStr.indexOf("ATG");
		//System.out.println("FIND START AT<"+start+">");
		if(isForward){
			for(int i=0;i<the_spanList.size();i++){
				Span ex = (Span)the_spanList.get(i);
				//System.out.println("\tEXON<"+ex+">");
				if(start<ex.getLength()){
					sc = new Span((start+ex.getStart()),
							(start+ex.getStart()+2));
					//System.out.println("\tRETURNING<"+sc+">");
					return sc;
				}else{
					start -= ex.getLength();
					//System.out.println("\tSTART NOW<"+start+">");
				}
			}
		}else{
			for(int i=(the_spanList.size()-1);i>=0;i--){
				Span ex = (Span)the_spanList.get(i);
				//System.out.println("\tEXON<"+ex+">");
				if(start<ex.getLength()){
					sc = new Span((start+ex.getStart()),
							(start+ex.getStart()+2));
					//System.out.println("\tRETURNING<"+sc+">");
					return sc;
				}else{
					start -= ex.getLength();
					//System.out.println("\tSTART NOW<"+start+">");
				}
			}
		}
		return sc;
	}

	private int calcRelSCPos(Span the_sc,Vector the_spanList){
		//System.out.print("CalcRelSCPos ");
		//if(the_spanList!=null){
		//	System.out.println("<"+the_spanList.size()+">");
		//}else{
		//	System.out.println("<0>\n");
		//}
		boolean isForward = true;
		//JUST FOR TEST OF LOCATION WITHIN AN EXON, THE SC IS MADE SMALLER
		Span scSpan = new Span(the_sc.getStart(),the_sc.getStart());
		if(the_sc.getStart()>the_sc.getEnd()){
			//REVERSE
			isForward = false;
		}
		int deductionLen = 0;
		if(isForward){
			//System.out.println("\tIS FORWARD");
			for(int i=0;i<the_spanList.size();i++){
				Span ex = (Span)the_spanList.get(i);
				//System.out.print("\tEXON SP<"+ex.toString()+">");
				if(ex.contains(scSpan)){
					//System.out.println(" CONTAINS <"
					//		+scSpan.toString()+">");
					deductionLen += (scSpan.getStart()-ex.getStart());
					return deductionLen;
				}else{
					//System.out.println(" HAS NO START CODON");
					deductionLen += ex.getLength();
				}
			}
		}else{
			//System.out.println("\tIS REVERSE");
			for(int i=0;i<the_spanList.size();i++){
				Span ex = (Span)the_spanList.get(i);
				//System.out.print("\tEXON SP<"+ex.toString()+">");
				if(ex.contains(scSpan)){
					//System.out.println("CONTAINS <"
					//		+scSpan.toString()+">");
					deductionLen += (-scSpan.getStart()+ex.getStart());
					return deductionLen;
				}else{
					//System.out.println("HAS NO START CODON");
					deductionLen += ex.getLength();
				}
			}
		}
		return deductionLen;
	}

	public int getProtLen(String the_len,String the_residue){
		int protLen = 0;
		if(the_len!=null){
			try{
				protLen = Integer.decode(the_len).intValue();
			}catch(Exception ex){
			}
		}
		if((protLen==0)&&(the_residue!=null)){
			return the_residue.length();
		}else{
			return protLen;
		}
	}

	public Element makeFeatHeader(Document the_DOC,
			GenFeat the_gf,Element the_FeatNode,
			String the_parentName,String the_parentType,
			String the_parentId){

		//System.out.println("FEAT HEADER FOR ID<"+the_gf.getId()+"> TYPE<"+the_gf.getType()+"> P_NAME<"+the_parentName+"> P_ID<"+the_parentId+"> P_TYPE<"+the_parentType+">");
		//UNIVERSAL HEADER (NAME, UNIQUENAME, FEATUREPROP,DBXREF,etc FOR
		//ALL FEATURES REPRESENTING ANNOTATION,FEATURE_SET,FEATURE_SPAN
		//ID PROCESSING
		String idTxt = the_gf.getId();
		if(idTxt!=null){
			//REMOVE SUFFIX FROM ID
			int dashSeq = idTxt.indexOf("_seq");
			if(dashSeq>0){
				idTxt = idTxt.substring(0,dashSeq);
			}
		}


		//PREPROCESS TYPE_ID
		String tmpTypeId = the_gf.getType();
		//System.out.println("GIVEN TYPE<"+tmpTypeId+">");
		if(tmpTypeId==null){
			//GUESS AT TYPE
			if(idTxt.indexOf("-R")>0){
				tmpTypeId = "mRNA";
			}else if(idTxt.indexOf(":")>0){
				tmpTypeId = "exon";
			}else if(the_gf instanceof FeatureSpan){
				tmpTypeId = "exon";
				the_gf.setType(tmpTypeId);
			}
		}
		//System.out.println("MOD1 TYPE<"+tmpTypeId+">");

		//SPECIAL FOR CR's WITH FeatureSets of type 'transcript'
		String specialTypeId = null;
		if((the_gf instanceof Annot)
				&&(idTxt!=null)&&(idTxt.startsWith("CR"))){
			if(the_gf instanceof Annot){
				if(tmpTypeId.startsWith("miscell")){
					tmpTypeId = "remark";
				}else{
					specialTypeId = "gene";
				}
			}
		}

		if((the_gf instanceof FeatureSet)
				&&(tmpTypeId.equals("transcript"))){
			//System.out.println("FOUND FEATURE_SET <"+the_gf.getId()+"> IN<"+the_parentId+"> OF TYPE TRANSCRIPT");
			tmpTypeId = "mRNA";
			if(!the_parentType.equals("gene")){
				//System.out.println("PARENT IS NOT GENE - USE SPECIAL");
				//PREEMPT THE REPRESENTATION OF THIS TRANSCRIPT
				//AS AN mRNA FOR THIS SPECIAL CASE
				specialTypeId = the_parentType;
			}else{
				//System.out.println("PARENT TYPE<"+the_parentType+"> - DONT USE SPECIAL");
			}
		}
		//System.out.println("MOD3 TYPE<"+tmpTypeId+">");

		tmpTypeId = convertTYPE(tmpTypeId);
		//System.out.println("MOD4 TYPE<"+tmpTypeId+">");


		//CORRECT FOR PROTEIN IDs HAVING A '-R'
		//PREFIX INSTEAD OF '-P'
		if(tmpTypeId.equals("aa")){
			if(idTxt.lastIndexOf("-R")>0){
				idTxt = textReplace(idTxt,"-R","-P");
				textCheck(idTxt);
			}
		}

		//MUNGE THE NAMES FOR start_codonS WHICH
		//ARE NOT UNIQUE IN GAME
		if(tmpTypeId.equals("start_codon")){
			idTxt = idTxt+"_start_codon";
		}

//UNIQUENAME PROCESSING
/***********************/
		//UNIQUENAME PROCESSING
		String uniquename = null;
		//UN = ID unless its a transcript with a 'temp' ID
		if(tmpTypeId.equals("remark")){
			uniquename = idTxt;
		}else if((the_gf instanceof Annot)
				&&(the_gf.getId()!=null)
				&&(the_gf.getId().startsWith("CR"))){
			uniquename = idTxt;
		}else if((the_gf instanceof FeatureSet)
				&&(the_parentId!=null)
				&&(the_parentId.startsWith("CR"))){
			uniquename = idTxt;
		}else if(tmpTypeId.equals("exon")){
			m_ExonCount++;
			if(idTxt==null){
				idTxt = the_parentName+":temp"+m_ExonCount;
				uniquename = baseName(the_parentName)+":temp"+m_ExonCount;
			}else{
				uniquename = idTxt;
			}
		}else if(tmpTypeId.equals("start_codon")){
			if(idTxt==null){
				uniquename = baseName(the_parentName)+"_start_codon";
			}else{
				uniquename = idTxt;
			}
		}else if(isvalidTransTYPE(tmpTypeId)){
			if((idTxt!=null)&&(idTxt.indexOf("temp")<=0)){
				uniquename = the_parentId+getTranSuffix(idTxt);
			}else{
				uniquename = the_parentId+getTranSuffix(the_gf.getName());
			}
		}else if(tmpTypeId.equals("gene")){
			if((the_parentName!=null)
				&&(the_parentName.indexOf("-R")>0)){
				System.out.println("DOES THIS EVER OCCUR????");
			}else{
				uniquename = idTxt;
				//System.out.println("ONLY THIS OCCURS");
			}
		}else if(tmpTypeId.equals("pseudogene")){
			uniquename = idTxt;
		}else if(tmpTypeId.equals("transposable_element")){
			uniquename = idTxt;
		}else{
			uniquename = idTxt;
			System.out.println("\tUNK TYPE<"+tmpTypeId+"> FOR <"+uniquename+">");
		}
		//LAST RESORT - GIVE UP HOPE
		if((uniquename==null)||(uniquename.equals(""))){
			uniquename = "UNKNOWN_UNIQUENAME";
		}

		//System.out.println("YIELD UN<"+uniquename+"> FOR TYPE<"+tmpTypeId+"> SPEC<"+specialTypeId+">");
/***********************/

		//WRITE HEADER ATTRIBUTES
		//ID
		if(idTxt!=null){
			the_FeatNode.setAttribute("id",idTxt);
		}

		//NAME
		if((the_gf.getName()!=null)
				&&(!(the_gf.getName().equals("")))){
			String tmpName = the_gf.getName();
			if(!(the_gf instanceof Annot)){
				//TRUNCATE '.3' FOR ALL
				//FEATURES BUT ANNOT
				if(tmpName.endsWith(".3")){
					tmpName = tmpName.substring(
							0,tmpName.length()-2);
				}
			}
			the_FeatNode.appendChild(makeGenericNode(
					the_DOC,"name",tmpName));
		}

		//UNIQUENAME
		if(uniquename!=null){
			if(!(the_gf instanceof Annot)){
				//TRUNCATE '.3' FOR ALL
				//FEATURES BUT ANNOT
				if(uniquename.endsWith(".3")){
					uniquename = uniquename.substring(
							0,uniquename.length()-2);
				}
			}
			the_FeatNode.appendChild(makeGenericNode(
					the_DOC,"uniquename",uniquename));
		}


		//CHECK FOR MULTIPLE TRANSCRIPTS WITH SAME UNIQUENAME
		if(isvalidTransTYPE(tmpTypeId)){
			for(int u=0;u<m_TranUNList.size();u++){
				String oldun = (String)m_TranUNList.get(u);
				if(oldun.equals(uniquename)){
					System.out.println("ERROR: TRAN UNIQUENAME<"
							+uniquename+"> IS REPEATED");
				}
			}
			m_TranUNList.add(uniquename);
		}

		//ORGANISM_ID
		the_FeatNode.appendChild(makeGenericNode(
				the_DOC,"organism_id","Dmel"));

		//MD5CHECKSUM
		if(the_gf instanceof FeatureSet){
			for(int i=0;i<the_gf.getGenFeatCount();i++){
				GenFeat gf = the_gf.getGenFeat(i);
				if((gf.getType()!=null)
						&&(gf.getType().equals("cdna"))){
					//STORE THE RESIDUES MD5 HERE
					if(gf.getMd5()!=null){
						the_FeatNode.appendChild(
							makeGenericNode(the_DOC,
								"md5checksum",
								gf.getMd5()));
					}
				}
			}
		}

		//TYPE_ID
		if(specialTypeId!=null){
			the_FeatNode.appendChild(makeGenericNode(
					the_DOC,"type_id",specialTypeId));
		}else if(tmpTypeId!=null){
			the_FeatNode.appendChild(makeGenericNode(
					the_DOC,"type_id",tmpTypeId));
		}

		//DATE
		if(the_gf.getdate()!=null){
			the_FeatNode.appendChild(makeChadoDateNode(
					the_DOC,"timeaccessioned",
					the_gf.getdate().toString()));
		}

		//RESIDUES
		if(the_gf instanceof Annot){
			//SEQLEN
			if(the_gf.getSpan()!=null){
				the_FeatNode.appendChild(makeGenericNode(
						the_DOC,"seqlen",
						(""+the_gf.getSpan().getLength())));
			}else{
				the_FeatNode.appendChild(makeGenericNode(
						the_DOC,"seqlen",
						"0"));
			}
		}else if(the_gf instanceof FeatureSet){
			for(int i=0;i<the_gf.getGenFeatCount();i++){
				GenFeat gf = the_gf.getGenFeat(i);
				if((gf.getType()!=null)
					&&(gf.getType().equals("cdna"))){
					//WRITE THE RESIDUE AS THIS FEAT'S
					String tmpRes = cleanString(
							gf.getResidues());
					//SEQLEN
					if(tmpRes!=null){
						the_FeatNode.appendChild(
							makeGenericNode(the_DOC,
								"seqlen",
								""+tmpRes.length()));
					}
					the_FeatNode.appendChild(
						makeGenericNode(the_DOC,
							"residues",
							tmpRes));
				}
			}
		}else if(the_gf instanceof FeatureSpan){
			//SEQLEN
			if(the_gf.getSpan()!=null){
				the_FeatNode.appendChild(makeGenericNode(
						the_DOC,"seqlen",
						(""+the_gf.getSpan().getLength())));
			}
		}

		//DBXREF_ID
		if((the_gf.getType()!=null)
				&&((the_gf.getType().equals("gene"))
				||(isvalidTransTYPE(the_gf.getType())))){
			if(isvalidIdTYPE(the_gf.getId())){
				the_FeatNode.appendChild(
						makeDbxrefIdAttrNode(the_DOC,
						"Gadfly",the_gf.getId()));
			}
		}

		//FEATURE_DBXREF
		//System.out.println("FEATURE_DBXREF");
		for(int i=0;i<the_gf.getAttribCount();i++){
			Attrib attr = the_gf.getAttrib(i);
			if(attr!=null){
				if(attr.getAttribType().equals("dbxref")){
					the_FeatNode.appendChild(
						makeFeatureDbxrefAttrNode(
						the_DOC,attr));
				//}else{
				//	System.out.println("ATTR_TYPE<"
				//		+attr.getAttribType()+">");
				}
			}
		}

		//AUTHOR
		if(the_gf.getAuthor()!=null){
			the_FeatNode.appendChild(makeFeaturePropNode(
					the_DOC,"owner",the_gf.getAuthor()));
		}

		//PROPERTY WHICH IS A protein_id
		for(int i=0;i<the_gf.getAttribCount();i++){
			Attrib attr = the_gf.getAttrib(i);
			if(attr!=null){
				if(attr.getAttribType().equals("property")){
					//TYPE="protein_id"THEN IT BECOMES A
					//	<feature_dbxref><dbxref_id>
					//	"SP:"+getvalue()<><>
					if(attr.gettype().equals("protein_id")){
						//MAY NEED TO BE DEFERRED
						//UNTIL AFTER THE
						//FEATURE_RELATIONSHIP!
						the_FeatNode.appendChild(
							makeFeaturePropAttrNode(the_DOC,attr));
					}
				}
			}
		}

		//PROPERTY WHICH IS NOT A protein_id NOR internal_synonym
		for(int i=0;i<the_gf.getAttribCount();i++){
			Attrib attr = the_gf.getAttrib(i);
			if(attr!=null){
				if(attr.getAttribType().equals("property")){
					//TYPE="protein_id"THEN IT BECOMES A
					//	<feature_dbxref><dbxref_id>
					//	"SP:"+getvalue()<><>
					if(!(attr.gettype().equals("protein_id"))&&(!(attr.gettype().equals("internal_synonym")))){
						the_FeatNode.appendChild(makeFeaturePropAttrNode(the_DOC,attr));
					}
				}
			}
		}

		//COMMENT
		for(int i=0;i<the_gf.getAttribCount();i++){
			Attrib attr = the_gf.getAttrib(i);
			if(attr!=null){
				if(attr.getAttribType().equals("comment")){
					the_FeatNode.appendChild(makeCommentAttrNode(the_DOC,attr));
				}
			}
		}

		//System.out.println("INTERNAL_SYNONYM");
		//INTERNAL SYNONYM FROM GAME internal_synonym PROPERTY
		for(int i=0;i<the_gf.getAttribCount();i++){
			Attrib attr = the_gf.getAttrib(i);
			if(attr!=null){
				if(attr.getAttribType().equals("property")){
					//System.out.println("\tCOULDBE TYPE<"+attr.gettype()+"> VAL<"+attr.getvalue()+">");
					if(attr.gettype().equals("internal_synonym")){
						//System.out.println("\tMADE <"+attr.getisinternal()+">");
						the_FeatNode.appendChild(makeFeatureSynonym(the_DOC,attr.getvalue(),attr.getisinternal(),the_gf.getAuthor()));
					}
				}
			}
		}

		//EXPLICIT SYNONYM 
		if((idTxt!=null)&&(the_gf.getName()!=null)
				&&(the_gf.getName().length()>0)
				&&(!(idTxt.equals(the_gf.getName())))){
			the_FeatNode.appendChild(makeFeatureSynonym(
					the_DOC,the_gf.getName(),
					"0",the_gf.getAuthor()));
		}

		if(the_gf instanceof FeatureSet){
			//System.out.println("TRANSCRIPT<"+the_gf.getId()+"> OF SPAN<"+the_gf.getSpan().toString()+">");
		}
		//FEATLOC
		if(the_gf.getSpan()!=null){
			the_FeatNode.appendChild(makeFeatureLoc(the_DOC,
					the_gf.getSpan(),true));
		}
		if(the_gf.getAltSpan()!=null){
			the_FeatNode.appendChild(makeFeatureLoc(the_DOC,
					the_gf.getAltSpan(),true));
		}

		//System.out.println("DONE FEAT HEADER");
		return the_FeatNode;
	}

	public Element makeChadoDateNode(Document the_DOC,
			String the_timeelement,String the_timestring){
		Element time = (Element)the_DOC.createElement(the_timeelement);
		String chadoDate = DateConv.GameDateToChadoDate(the_timestring);
		time.appendChild(the_DOC.createTextNode(chadoDate));
		return time;
	}


	public String getTranSuffix(String the_name){
		String suffix = "";
		if(the_name==null){
			return null;
		}
		int indx = the_name.lastIndexOf("-R");
		if(indx>0){
			suffix = the_name.substring(indx);
		}
		return suffix;
	}

	public String getProtSuffix(String the_name){
		String suffix = "";
		if(the_name==null){
			return null;
		}
		int indx = the_name.lastIndexOf("-P");
		if(indx>0){
			suffix = the_name.substring(indx);
		}
		return suffix;
	}

	public String getBase(String the_str){
		if(the_str!=null){
			int indx = the_str.lastIndexOf("-");
			if(indx>0){
				the_str = the_str.substring(0,indx);
			}
		}
		return the_str;
	}

	public Element makeFeatureSynonym(Document the_DOC,String the_synonymTxt,String the_internalFlag,String the_Author){
		Element fsNode = (Element)the_DOC.createElement("feature_synonym");
		fsNode.appendChild(makeGenericNode(the_DOC,"is_internal",the_internalFlag));
		//SYNONYM_ID
		Element synIdNode = (Element)the_DOC.createElement("synonym_id");
		Element synNode = (Element)the_DOC.createElement("synonym");
		synNode.appendChild(makeGenericNode(the_DOC,"name",
				the_synonymTxt));
		synNode.appendChild(makeGenericNode(the_DOC,"synonym_sgml",
				the_synonymTxt));
		synNode.appendChild(makeGenericNode(the_DOC,"type_id",
				"synonym"));
		synIdNode.appendChild(synNode);
		fsNode.appendChild(synIdNode);
		//PUB_ID
		String pubId = null;//"curator";
		if(the_Author!=null){
			pubId = the_Author;//+" "+pubId;
		}else{
			pubId = "gadfly3";//+" "+pubId;
		}
		fsNode.appendChild(makeGenericNode(the_DOC,"pub_id",pubId));
		fsNode.appendChild(makeGenericNode(the_DOC,"is_current","1"));
		return fsNode;
	}

	public Element makeGenericNode(Document the_DOC,
			String the_type,String the_text){
		Element genNode = (Element)the_DOC.createElement(the_type);
		if(the_text!=null){
			genNode.appendChild(the_DOC.createTextNode(the_text));
		}
		return genNode;
	}

	public Element makeFeaturePropNode(Document the_DOC,
			String the_pkey_id,String the_pval){
		Element fpNode = (Element)the_DOC.createElement("featureprop");
		if(the_pkey_id!=null){
			fpNode.appendChild(makeGenericNode(
					the_DOC,"type_id",the_pkey_id));
		}
		if(the_pval!=null){
			fpNode.appendChild(makeGenericNode(
					the_DOC,"value",the_pval));
		}
		return fpNode;
	}

	public Element makeFeaturePropAttrNode(Document the_DOC,
			Attrib the_attr){
		String prefix = null;
		Element atNode = (Element)the_DOC.createElement("featureprop");
		if(the_attr.gettype()!=null){
			atNode.appendChild(makeGenericNode(
					the_DOC,"type_id",the_attr.gettype()));
		}
		if(the_attr.getvalue()!=null){
			//Element pval = (Element)the_DOC.createElement("pval");
			Element pval = (Element)the_DOC.createElement("value");
			String tmp = the_attr.getvalue();
			if(the_attr.getdate()!=null){
				String chadoDate = DateConv.GameDateToChadoDate(
						the_attr.getdate().toString());
				tmp += "::DATE:"+chadoDate;
			}
			if(the_attr.gettimestamp()!=null){
				tmp += "::TS:"+the_attr.gettimestamp();
			}
			if((prefix!=null)&&(!(tmp.startsWith(prefix)))){
				tmp = prefix+tmp;
			}
			pval.appendChild(the_DOC.createTextNode(tmp));
			atNode.appendChild(pval);
		}
		return atNode;
	}

	public Element makeDbxrefIdAttrNode(Document the_DOC,
			String the_xref_db,String the_xref_id){
		Element atNode = (Element)the_DOC.createElement("dbxref_id");
		Element dbxrefNode = (Element)the_DOC.createElement("dbxref");
		if(the_xref_id!=null){
			dbxrefNode.appendChild(makeGenericNode(
					the_DOC,"accession",the_xref_id));
		}
		if(the_xref_db!=null){
			String dbname = convertDB_NAME(the_xref_db);
			dbxrefNode.appendChild(makeGenericNode(
					the_DOC,"db_id",dbname));
		}
		atNode.appendChild(dbxrefNode);
		return atNode;
	}

	public Element makeFeatureDbxrefAttrNode(Document the_DOC,Attrib the_attr){
		Element attributeNode = (Element)the_DOC.createElement("feature_dbxref");
		attributeNode.appendChild(makeDbxrefIdAttrNode(the_DOC,
				the_attr.getxref_db(),the_attr.getdb_xref_id()));
		return attributeNode;
	}

	public Element makeCommentAttrNode(Document the_DOC,Attrib the_attr){
		Element attributeNode = (Element)the_DOC.createElement("featureprop");
		Element pkey_id = (Element)the_DOC.createElement("type_id");
		pkey_id.appendChild(the_DOC.createTextNode("comment"));
		attributeNode.appendChild(pkey_id);
		if(the_attr.gettext()!=null){
			Element pval = (Element)the_DOC.createElement("value");
			String tmp = the_attr.gettext();
			if(the_attr.getdate()!=null){
				String chadoDate = DateConv.GameDateToChadoDate(
						the_attr.getdate().toString());
				tmp += "::DATE:"+chadoDate;
			}
			if(the_attr.gettimestamp()!=null){
				tmp += "::TS:"+the_attr.gettimestamp();
			}
			pval.appendChild(the_DOC.createTextNode(tmp));
			attributeNode.appendChild(pval);
		}
		if(the_attr.getperson()!=null){
			Element featureprop_pub = (Element)the_DOC.createElement("featureprop_pub");
			featureprop_pub.appendChild(makeGenericNode(
					the_DOC,"pub_id",
					the_attr.getperson()));
			attributeNode.appendChild(featureprop_pub);
		}
		return attributeNode;
	}

	public Element makeGameTempStorage(Document the_DOC,
			String the_pkey,String the_pval){
		Element atNode = (Element)the_DOC.createElement("featureprop");
		atNode.appendChild(makeGenericNode(the_DOC,"type_id",the_pkey));
		atNode.appendChild(makeGenericNode(the_DOC,"value",the_pval));
		return atNode;
	}

	public Element makeFeatureLoc(Document the_DOC,Span the_span,
			boolean the_advance){
		Element featloc = (Element)the_DOC.createElement("featureloc");
		Element srcfeat = (Element)the_DOC.createElement("srcfeature_id");

		//SPAN
		//ONLY ADJUST A SPAN TO NEW COORDINATES IF IT IS WITH RESPECT
		//TO THE REF_SPAN, OTHER AltSpan()s FROM <result_span> SHOULD
		//NOT BE ADJUSTED
		//System.out.println("REFSTRING<"+m_NewREFSTRING
		//		+"> SRC<"+the_span.getSrc()+">");
		String refStr = null;
		Span tmp_span = the_span;
		if(the_advance){
		if((m_OldREFSTRING!=null)&&(the_span.getSrc()!=null)
				&&(the_span.getSrc().equals(m_OldREFSTRING))){
			tmp_span = the_span.advance(m_REFSPAN.getStart()-1);
			//System.out.println("ADVANCING ID<"+the_span.getSrc()
			//		+">\tSP<"+the_span
			//		+">\tTO<"+tmp_span+">");
			refStr = m_NewREFSTRING;
		}else{
			refStr = the_span.getSrc();
		}
		}
		if(refStr!=null){
			srcfeat.appendChild(the_DOC.createTextNode(refStr));
			featloc.appendChild(srcfeat);
		}

		int localMin = tmp_span.getStart();
		int localMax = tmp_span.getEnd();
		if(localMin>tmp_span.getEnd()){
			localMin = tmp_span.getEnd();
		}
		if(localMax<tmp_span.getStart()){
			localMax = tmp_span.getStart();
		}

		//NBEG
		Element nbeg = (Element)the_DOC.createElement("fmin");
		nbeg.appendChild(the_DOC.createTextNode((""+localMin)));
		featloc.appendChild(nbeg);

		//NEND
		Element nend = (Element)the_DOC.createElement("fmax");
		nend.appendChild(the_DOC.createTextNode((""+localMax)));
		featloc.appendChild(nend);

		//STRAND
		Element strand = (Element)the_DOC.createElement("strand");
		if(tmp_span.isForward()){
			strand.appendChild(the_DOC.createTextNode("1"));
		}else{
			strand.appendChild(the_DOC.createTextNode("-1"));
		}
		featloc.appendChild(strand);
		return featloc;
	}



	public void preprocessCVTerms(GenFeat the_TopNode){
	//EXCLUDE TEs FOR NOW
	if((the_TopNode.getId()!=null)&&(the_TopNode.getId().startsWith("TE"))){
		return;
	}

	if((the_TopNode instanceof ModFeat)||(the_TopNode instanceof Seq)){
		//IGNORE
	}else if(the_TopNode instanceof Aspect){
		storePUB("Gadfly","curator");
		if(((Aspect)the_TopNode).getFunction()!=null){
			storeCVOnly("molecular_function");
		}
		if(((Aspect)the_TopNode).getComponent()!=null){
			storeCV("component","cellular_component");
			storeCVOnly("cellular_component");
		}
		if(((Aspect)the_TopNode).getProcess()!=null){
			storeCV("process","biological_process");
			storeCVOnly("biological_process");
		}
	}else{
		//System.out.println("PREPROCESS TYPE<"+the_TopNode.getType()+">");
		if((m_modeflags==WRITEALL)||(the_TopNode.isChanged())){

		if((m_parseflags==GameSaxReader.PARSEALL)
				||(the_TopNode instanceof Annot)
				||(the_TopNode instanceof FeatureSet)
				||(the_TopNode instanceof FeatureSpan)){

			//SYNONYM
			if((the_TopNode.getId()!=null)
					&&(the_TopNode.getName()!=null)
					&&(!(the_TopNode.getId().equals(
					the_TopNode.getName())))){
				storeCV("synonym","synonym type");
			}

			//TYPES
			//FIX TO GET AROUND BUG WHERE GAME LISTS THE
			//EXON TYPE AS 'piecegenie' OR SOME SUCH TRIPE
			if(the_TopNode instanceof FeatureSpan){
					the_TopNode.setType(convertExonTYPE(
							the_TopNode.getType()));
			}

			if((the_TopNode.getType()!=null)
					&&(the_TopNode.getType().equals("gene"))
					&&(the_TopNode instanceof FeatureSet)){
				the_TopNode.setType("mRNA");
			}

			if(the_TopNode.getType()!=null){
				String tt = the_TopNode.getType();
				//if(tt.startsWith("pseudo")){
					//IGNORE
				//}else{
					storeCV(convertTYPE(the_TopNode.getType()),"SO");
				//}
			}else{
				//NO TYPE - NEED TO GUESS
				if((the_TopNode.getId()!=null)
						&&(the_TopNode.getId().indexOf("-R")>0)){
					storeCV(convertTYPE("mRNA"),"SO");
				}else if((the_TopNode.getId()!=null)
						&&(the_TopNode.getId().indexOf("-P")>0)){
					storeCV("protein","SO");
				}
			}

			//AUTHOR
			if(the_TopNode.getAuthor()!=null){
				storeCV("owner","property type");
				storePUB(the_TopNode.getAuthor(),"curator");
			}

			//DBXREF_ID
			if((the_TopNode.getType()!=null)
					&&((the_TopNode.getType().equals("gene"))
					||(the_TopNode.getType().startsWith("transposable"))
					||(isvalidTransTYPE(the_TopNode.getType())))){
				if(isvalidIdTYPE(the_TopNode.getId())){
						storeDB("Gadfly");
				}
			}

			//FEATURE_DBXREF
			for(int i=0;i<the_TopNode.getAttribCount();i++){
				Attrib attr = the_TopNode.getAttrib(i);
				if(attr!=null){
				String atTp = attr.getAttribType();
				if(atTp!=null){
					if(atTp.equals("dbxref")){
						storeDB(convertDB_NAME(attr.getxref_db()));
					}else if(atTp.equals("comment")){
						storeCV(attr.getAttribType(),"property type");
					}else if(atTp.equals("internal_synonym")){
						storeCV("synonym","synonym type");
					}else{
						//System.out.println("ATTR<"+attr.getAttribType()+">");
					}
				}
				if(attr.gettype()!=null){
					if(attr.gettype().equals("internal_synonym")){					
						storeCV("synonym","synonym type");
					}else{
						storeCV(attr.gettype(),"property type");
					}
				}
				if(attr.getperson()!=null){
					storePUB(attr.getperson(),"curator");
				}
				}
			}
		}

		//RECURSE
		for(int i=0;i<the_TopNode.getGenFeatCount();i++){
			GenFeat gf = the_TopNode.getGenFeat(i);
			preprocessCVTerms(gf);
		}
		}
	}//END EXCLUDE MODFEAT
	}

	public Element makePreamble(Document the_DOC,Element the_Elem){
		if(m_CVList!=null){
			Iterator it = m_CVList.iterator();
			while(it.hasNext()){
				String txt = (String)it.next();
				the_Elem.appendChild(createCV(the_DOC,txt));
			}
		}
		if(m_DBList!=null){
			Iterator it = m_DBList.iterator();
			while(it.hasNext()){
				String txt = (String)it.next();
				the_Elem.appendChild(createDB(the_DOC,txt));
			}
		}
		if(m_CVTERMList!=null){
			Iterator it1 = m_CVTERMList.iterator();
			while(it1.hasNext()){
				String txt = (String)it1.next();
				int indx = 0;
				if((indx = txt.indexOf("|"))>0){
					String txt1 = txt.substring(0,indx);
					if(isvalidCVTERM(txt1)){
						String txt2 = txt.substring(indx+1);
						the_Elem.appendChild(createCVTERM(the_DOC,txt1,txt2));
					}
				}
			}
		}
		//PUBLICATIONS
		if(m_PUBList!=null){
			Iterator it2 = m_PUBList.iterator();
			while(it2.hasNext()){
				String txt = (String)it2.next();
				txt = convertPUB_NAME(txt);
				the_Elem.appendChild(createPUB(the_DOC,txt));
			}
		}
		//ORGANISM
		the_Elem.appendChild(createORGANISM(the_DOC));
		return the_Elem;
	}

	public void storeCVOnly(String the_cvTxt){
		if(m_CVList==null){
			m_CVList = new HashSet();
		}
		the_cvTxt = convertTYPE(the_cvTxt);
		m_CVList.add(the_cvTxt);
	}

	public void storeCV(String the_cvTxt,String the_cvtermTxt){
		if(m_CVList==null){
			m_CVList = new HashSet();
		}
		if(m_CVTERMList==null){
			m_CVTERMList = new HashSet();
		}
		the_cvTxt = convertTYPE(the_cvTxt);
		m_CVList.add(the_cvtermTxt);
		m_CVTERMList.add(the_cvTxt+"|"+the_cvtermTxt);
	}

	public Element createCV(Document the_DOC,String txt){
		Element cv = (Element)the_DOC.createElement("cv");
		cv.setAttribute("op","lookup");
		cv.setAttribute("id",txt);
		Element cvname = (Element)the_DOC.createElement("name");
		cvname.appendChild(the_DOC.createTextNode(txt));
		cv.appendChild(cvname);
		return cv;
	}

	public Element createDB(Document the_DOC,String txt){
		Element db = (Element)the_DOC.createElement("db");
		db.setAttribute("op","lookup");
		db.setAttribute("id",txt);
		Element dbname = (Element)the_DOC.createElement("name");
		dbname.appendChild(the_DOC.createTextNode(txt));
		db.appendChild(dbname);
		return db;
	}

	public Element createCVTERM(Document the_DOC,String txt,String txt1){
		Element cvterm = (Element)the_DOC.createElement("cvterm");
		cvterm.setAttribute("op","lookup");
		cvterm.setAttribute("id",txt);
		Element cv_id = (Element)the_DOC.createElement("cv_id");
		cv_id.appendChild(the_DOC.createTextNode(txt1));
		cvterm.appendChild(cv_id);
		Element termnameNode = (Element)the_DOC.createElement("name");
		termnameNode.appendChild(the_DOC.createTextNode(txt));
		cvterm.appendChild(termnameNode);
		return cvterm;
        }

	public void storePUB(String the_curatorTxt,String the_noteTxt){
		storeCV(the_noteTxt,"pub type");
		if(m_PUBList==null){
			m_PUBList = new HashSet();
		}
		m_PUBList.add(the_curatorTxt);
	}

	public void storeDB(String the_dbTxt){
		if(m_DBList==null){
			m_DBList = new HashSet();
		}
		m_DBList.add(the_dbTxt);
	}

	public Element createPUB(Document the_DOC,String the_txt){
		Element pub = (Element)the_DOC.createElement("pub");
		if(the_txt.startsWith("Gad")){
			pub.setAttribute("op","force");
		}else{
			pub.setAttribute("op","lookup");
		}
		pub.setAttribute("id",the_txt);
		Element miniref = (Element)the_DOC.createElement("miniref");
		miniref.appendChild(the_DOC.createTextNode(the_txt));
		pub.appendChild(miniref);
		Element type_id = (Element)the_DOC.createElement("type_id");
		type_id.appendChild(the_DOC.createTextNode("curator"));
		pub.appendChild(type_id);
		return pub;
	}

	public Element createORGANISM(Document the_DOC){
		Element organism = (Element)the_DOC.createElement("organism");
		organism.setAttribute("id","Dmel");
		Element genus = (Element)the_DOC.createElement("genus");
		genus.appendChild(the_DOC.createTextNode("Drosophila"));
		organism.appendChild(genus);
		Element species = (Element)the_DOC.createElement("species");
		species.appendChild(the_DOC.createTextNode("melanogaster"));
		organism.appendChild(species);
		return organism;
	}

	public String cleanString(String the_seq){
		StringBuffer sbuf = new StringBuffer();
                if(the_seq!=null){
                        int miscChar = 0;
                        int len = the_seq.length();
                        byte[] b = the_seq.getBytes();
			char[] c = the_seq.toCharArray();
                        for(int i=0;i<len;i++){
                                if((b[i]=='\n')||(b[i]==32)){
                                        miscChar++;
                                }else{
					sbuf.append(c[i]);
				}
                        }
                }
                return sbuf.toString();
        }

	public String convertDB_NAME(String the_dbname){
		if(the_dbname==null){
			return null;
		}else if(the_dbname.equalsIgnoreCase("gadfly")){
			return "Gadfly";
		}else if((the_dbname.equalsIgnoreCase("flybase"))
				||(the_dbname.equalsIgnoreCase("FB"))){
			return "FlyBase";
		}else if(the_dbname.equalsIgnoreCase("genbank")){
			return "genbank";
		}else if(the_dbname.equalsIgnoreCase("gb")){
			return "genbank";
		}else{
			return the_dbname;
		}
	}

	public String convertPUB_NAME(String the_pubname){
		if(the_pubname==null){
			return null;
		}else if(the_pubname.equalsIgnoreCase("gadfly")){
			return "gadfly3";
		}else{
			return the_pubname;
		}
	}

	public String convertTYPE(String the_term){
		//System.out.println("CONVERTING<"+the_term+">");
		if(the_term==null){
			return "NNNN";
		}else if(the_term.equals("cdna")){
			return "cDNA";
		}else if(the_term.equals("transcript")){
			return "mRNA";
		}else if(the_term.equals("transposable_element")){
			return "transposable_element";
		}else if(the_term.equals("transposon")){
			return "transposable_element";
		}else if(the_term.equals("aa")){
			return "protein";
		}else if(the_term.equals("pseudogene")){
			return "pseudogene";
		}else if(the_term.equals("pseudotranscript")){
			return "mRNA";
		}else if(the_term.startsWith("misc. non-coding RNA")){
			return "ncRNA";
		}else if(the_term.startsWith("microRNA")){
			return "nuclear_micro_RNA_coding_gene";
		}else if(the_term.startsWith("miscellaneous curator's observation")){
			return "remark";
		}else{
			return the_term;
		}
	}

	public String convertExonTYPE(String the_term){
		if(the_term==null){
			return null;
		}
		if((the_term.equals("start_codon"))
				||(the_term.equals("protein"))
				||(the_term.equals("exon"))){
			return the_term;
		}else if(the_term.startsWith("translate")){
			return "start_codon";
		}else{
			//System.out.println("PREPROCESS CONVERT EXON TYPE<"
			//		+the_term+"> TO <exon>");
			return "exon";
		}
	}

	public boolean isvalidTransTYPE(String the_type){
		if(the_type==null){
			return false;
		}
		if((the_type.equals("mRNA"))
				||(the_type.equals("tRNA"))
				||(the_type.equals("rRNA"))
				||(the_type.equals("snRNA"))
				||(the_type.equals("snoRNA"))
				||(the_type.equals("nuclear_micro_RNA_coding_gene"))
				||(the_type.equals("pseudogene"))
				||(the_type.equals("remark"))
				||(the_type.equals("ncRNA"))){
			return true;
		}else{
			return false;
		}
	}

	public boolean isvalidCVTERM(String the_term){
		if(the_term==null){
			return false;
		}else if(the_term.equals("start_codon")){
			return false;
		}
		return true;
	}

	public boolean isvalidIdTYPE(String the_term){
		if(the_term==null){
			return false;
		}
		if((the_term.startsWith("CG"))
				||(the_term.startsWith("CR"))){
			return true;
		}
		return false;
	}

	public Element makeAnalysisNode(Document the_DOC,GenFeat the_gf){
		System.out.println("START NON_ANNOT_SEQ NODE");
		Element featNode = (Element)the_DOC.createElement("feature");

		String idStr = null;
		String nameStr = null;
		String uniquenameStr = null;
		for(int i=0;i<the_gf.getGenFeatCount();i++){
			GenFeat gf = the_gf.getGenFeat(i);
			idStr = gf.getId();
			nameStr = gf.getName();
			uniquenameStr = gf.getId();
			System.out.println("\tRESULT_SET ID <"+idStr+">");
			System.out.println("\tRESULT_SET NAME<"+nameStr+">");
			//System.out.println("\tRESULT_SET UNIQUENAME<"+uniquenameStr+">");
			for(int j=0;j<gf.getGenFeatCount();j++){
				GenFeat spangf = gf.getGenFeat(j);
				//uniquenameStr = spangf.getId();
				//System.out.println("RES_SPAN TYPE<"
				//		+spangf.getType()+uniquenameStr+">");
			}
		}

		//ID
		if(the_gf.getId()!=null){
			featNode.setAttribute("id",the_gf.getId());
		}

		//DATE
		if(the_gf.getdate()!=null){
			featNode.appendChild(makeChadoDateNode(
					the_DOC,"timeaccessioned",
					the_gf.getdate().toString()));
		}

		//NAME
		if(nameStr==null){
			nameStr = "PROBLEM"+the_gf.getName();
		}
		if(nameStr!=null){
			featNode.appendChild(makeGenericNode(
					the_DOC,"name",nameStr));
		}

		//DATE
		if(the_gf.getdate()!=null){
			featNode.appendChild(makeChadoDateNode(
					the_DOC,"timelastmodified",
					the_gf.getdate().toString()));
			//NOT REALLY TIMELASTMOD, BUT TIMEACC
			//SINCE GAME HAS ONLY ONE PLACE FOR DATE
		}

		//SEQLEN
		if(the_gf.getResidueLength()!=null){
			featNode.appendChild(makeGenericNode(
					the_DOC,"seqlen",the_gf.getResidueLength()));
		}else{
			featNode.appendChild(makeGenericNode(
					the_DOC,"seqlen","0"));
		}

		//UNIQUENAME
		//String uniquename = the_gf.getName();
		if(uniquenameStr==null){
			uniquenameStr = "PROBLEM"+the_gf.getId();
		}
		//if(uniquename==null){
		//	uniquename = "UNKNOWN";
		//}

		featNode.appendChild(makeGenericNode(
				the_DOC,"uniquename",uniquenameStr));


		//MD5CHECKSUM
		if(the_gf.getMd5()!=null){
			featNode.appendChild(makeGenericNode(
					the_DOC,"md5checksum",the_gf.getMd5()));
		}

		//ORGANISM_ID
		//featNode.appendChild(makeGenericNode(
		//		the_DOC,"organism_id","Dmel"));
		featNode.appendChild(makeCAOrganismId(the_DOC,
				"Computational","Result"));

		//TYPE_ID
		featNode.appendChild(makeGenericNode(
				the_DOC,"type_id","match"));

		//ANALYSIS
		featNode.appendChild(makeGenericNode(
				the_DOC,"is_analysis","1"));

		featNode.appendChild(makeAnalysisfeatureNode(the_DOC,the_gf));
		System.out.println("COMP_ANAL ID<"+the_gf.getId()+">");
		System.out.println("COMP_ANAL NAME<"+the_gf.getName()+">");

		/**********************
		//UNIQUENAME
		featNode.appendChild(makeGenericNode(
				the_DOC,"uniquename",m_NewREFSTRING));

		//ORGANISM_ID
		featNode.appendChild(makeGenericNode(
					the_DOC,"organism_id","Dmel"));
		//TYPE_ID
		featNode.appendChild(makeGenericNode(
				the_DOC,"type_id","match"));
		**********************/

		for(int i=0;i<the_gf.getGenFeatCount();i++){
			GenFeat gf = the_gf.getGenFeat(i);
			System.out.println("\tRESULT_SET ID<"+gf.getId()+">");
			System.out.println("\tRESULT_SET NAME<"+gf.getName()+">");
			featNode.appendChild(makeCAFeatRel(the_DOC,"partof",
					makeRSFeature(the_DOC,gf)));
		}

		//featNode.appendChild(makeCAFeatRel(the_DOC,"partof",
		//		makeRSFeature(the_DOC,the_gf)));
		return featNode;
	}

	public Element makeAnalysisfeatureNode(Document the_DOC,GenFeat the_gf){
		System.out.println("START NON_ANNOT_SEQ NODE");
		Element afNode = (Element)the_DOC.createElement("analysisfeature");
		Element aidNode = (Element)the_DOC.createElement("analysis_id");
		Element aNode = (Element)the_DOC.createElement("analysis");
		System.out.println("STFF COULD BE<"+the_gf.getDatabase()+">");
		System.out.println("STFF2 COULD BE<"+the_gf.getProgram()+">");
		//na_affy_oligo.dros
		if(the_gf.getDatabase()!=null){
			aNode.appendChild(makeGenericNode(
					the_DOC,"sourcename",the_gf.getDatabase()));
		}
//RRR WRONG DATE
		//DATE
		if(the_gf.getdate()!=null){
			aNode.appendChild(makeChadoDateNode(
					the_DOC,"timeexecuted",
					the_gf.getdate().toString()));
		}
		//1.0
		aNode.appendChild(makeGenericNode(
				the_DOC,"sourceversion","1.0"));
		//sim4
		if(the_gf.getProgram()!=null){
			aNode.appendChild(makeGenericNode(
					the_DOC,"program",the_gf.getProgram()));
		}
		//1.0
		aNode.appendChild(makeGenericNode(
				the_DOC,"programversion","1.0"));
		aidNode.appendChild(aNode);
		afNode.appendChild(aidNode);
		return afNode;
	}

	public Element makeCAFeatRel(Document the_DOC,String the_relType,
			Element the_subjFeat){
			//subject_id,type_id
		Element featrel = (Element)the_DOC.createElement(
				"feature_relationship");
		Element subjfeat = (Element)the_DOC.createElement("subject_id");
		subjfeat.appendChild(the_subjFeat);
		featrel.appendChild(subjfeat);
		featrel.appendChild(makeGenericNode(
				the_DOC,"type_id",the_relType));
		return featrel;
	}

	public Element makeRSFeature(Document the_DOC,GenFeat the_gf){
		System.out.println("MAKE Result_Set Feature");
		Element RSfeat = (Element)the_DOC.createElement("feature");

		String idStr = null;
		for(int j=0;j<the_gf.getGenFeatCount();j++){
			GenFeat gff = the_gf.getGenFeat(j);
			idStr = gff.getId();
		}
		if(idStr!=null){
			RSfeat.appendChild(makeGenericNode(
					the_DOC,"uniquename",idStr));
		}

		RSfeat.appendChild(makeCAOrganismId(the_DOC,
				"Computational","Result"));

		//TYPE_ID
		RSfeat.appendChild(makeGenericNode(
				the_DOC,"type_id","match"));

		for(int j=0;j<the_gf.getGenFeatCount();j++){
			GenFeat gff = the_gf.getGenFeat(j);
			System.out.println("\t\tRESULT_SPAN ID<"
					+gff.getId()+">");
			System.out.println("\t\tRESULT_SPAN NAME<"
					+gff.getName()+">");
			System.out.println("\tFFFFFFFF1 -RESIDUES <"
					+gff.getResidues()+">");
			String residues = gff.getResidues();

			if(gff.getAltSpan()!=null){
				Element srcf2 = makeCASrcFeatResult(the_DOC,
						the_gf,gff.getAltSpan().getSrc(),
						residues);
				RSfeat.appendChild(makeCAFeatureLoc(
						the_DOC,gff.getAltSpan(),
						true,srcf2));
			}

			if(gff.getSpan()!=null){
				Element srcf1 = makeCASrcFeatRefr(the_DOC,gff);
				//ADVANCE
				Span sp = gff.getSpan();
				sp = sp.advance(m_REFSPAN.getStart()-1);
				RSfeat.appendChild(makeCAFeatureLoc(
						the_DOC,sp,false,srcf1));
			}
		}
		return RSfeat;
	}

	public Element makeCASrcFeatRefr(Document the_DOC,GenFeat the_gf){
		Element srcFeat = (Element)the_DOC.createElement("feature");
		//RESIDUES
		//if(the_gf.getResidues()!=null){
		//	//System.out.println("\tRESIDUES OF LEN<"
		//	//		+the_gf.getResidues().length()+">");
		//	String tmpRes = cleanString(the_gf.getResidues());
		//	srcFeat.appendChild(makeGenericNode(the_DOC,
		//			"residues",tmpRes));
		//}
		//UNIQUENAME
		if((the_gf.getSpan()!=null)&&(the_gf.getSpan().getSrc()!=null)){
			String spanSrc = the_gf.getSpan().getSrc();
			srcFeat.appendChild(makeGenericNode(
					the_DOC,"uniquename",spanSrc));
		}
		//ORGANISM_ID
		srcFeat.appendChild(makeCAOrganismId(the_DOC,
				"Drosophila","Melanogaster"));
		//TYPE_ID
		srcFeat.appendChild(makeGenericNode(
				the_DOC,"type_id","chromosome_arm"));
		//DBXREF_ID
		srcFeat.appendChild(makeDbxrefIdAttrNode(the_DOC,
				"Gadfly",m_NewREFSTRING));
		return srcFeat;
	}

	public Element makeCASrcFeatResult(Document the_DOC,
			GenFeat the_gf,String the_src,
			String the_residues){
		Element srcFeat = (Element)the_DOC.createElement("feature");
		//TIMEACCESSIONED
		if(the_gf.getdate()!=null){
			srcFeat.appendChild(makeChadoDateNode(
					the_DOC,"timeaccessioned",
					the_gf.getdate().toString()));
		}

		//NAME
		if(the_src!=null){
			srcFeat.appendChild(makeGenericNode(
					the_DOC,"name",the_src));
		}

		//RESIDUES
		if(the_residues!=null){
			String tmpRes = cleanString(the_residues);
			srcFeat.appendChild(makeGenericNode(the_DOC,
					"residues",tmpRes));
		}

		//TIMELASTMODIFIED
		//UNIQUENAME
		if(the_src!=null){
			srcFeat.appendChild(makeGenericNode(
					the_DOC,"uniquename",the_src));
		}
		//srcFeat.appendChild(makeGenericNode(
		//		the_DOC,"uniquename",the_gf.getId()));

		//SEQLEN
		//MD5CHECKSUM
		//ORGANISM_ID
		srcFeat.appendChild(makeCAOrganismId(the_DOC,
				"Computational","Result"));
		//TYPE_ID
		//srcFeat.appendChild(makeGenericNode(
		//		the_DOC,"type_id",the_gf.getType()));
		srcFeat.appendChild(makeGenericNode(
				the_DOC,"type_id","STUFF"));
		return srcFeat;
	}

	public Element makeCAOrganismId(Document the_DOC,
			String the_genus,String the_species){
		Element oiFeat = (Element)the_DOC.createElement("organism_id");
		Element oioFeat = (Element)the_DOC.createElement("organism");
		Element genusFeat = (Element)the_DOC.createElement("genus");
		genusFeat.appendChild(the_DOC.createTextNode(the_genus));
		oioFeat.appendChild(genusFeat);
		Element speciesFeat = (Element)the_DOC.createElement("species");
		speciesFeat.appendChild(the_DOC.createTextNode(the_species));
		oioFeat.appendChild(speciesFeat);
		oiFeat.appendChild(oioFeat);
		return oiFeat;
	}

	public Element makeCAFeatureLoc(Document the_DOC,Span the_span,
			boolean the_advance,Element the_srcFeat){
		Element featloc = (Element)the_DOC.createElement("featureloc");
		Element srcfeat = (Element)the_DOC.createElement("srcfeature_id");

		//SPAN
		//ONLY ADJUST A SPAN TO NEW COORDINATES IF IT IS WITH RESPECT
		//TO THE REF_SPAN, OTHER AltSpan()s FROM <result_span> SHOULD
		//NOT BE ADJUSTED
		//System.out.println("REFSTRING<"+m_NewREFSTRING
		//		+"> SRC<"+the_span.getSrc()+">");
		String refStr = null;
		Span tmp_span = the_span;
		if(the_advance){
		if((m_OldREFSTRING!=null)&&(the_span.getSrc()!=null)
				&&(the_span.getSrc().equals(m_OldREFSTRING))){
			tmp_span = the_span.advance(m_REFSPAN.getStart()-1);
			refStr = m_NewREFSTRING;
		}else{
			refStr = the_span.getSrc();
		}
		}
		if(the_srcFeat!=null){
			srcfeat.appendChild(the_srcFeat);
			featloc.appendChild(srcfeat);
		}

		int localMin = tmp_span.getStart();
		int localMax = tmp_span.getEnd();
		if(localMin>tmp_span.getEnd()){
			localMin = tmp_span.getEnd();
		}
		if(localMax<tmp_span.getStart()){
			localMax = tmp_span.getStart();
		}

		//IS_FMIN_PARTIAL
		Element fmin_part = (Element)the_DOC.createElement("is_fmin_partial");
		fmin_part.appendChild(the_DOC.createTextNode((""+0)));
		featloc.appendChild(fmin_part);

		//IS_FMAX_PARTIAL
		Element fmax_part = (Element)the_DOC.createElement("is_fmax_partial");
		fmax_part.appendChild(the_DOC.createTextNode((""+0)));
		featloc.appendChild(fmax_part);

		//FMIN
		Element fmin = (Element)the_DOC.createElement("fmin");
		fmin.appendChild(the_DOC.createTextNode((""+localMin)));
		featloc.appendChild(fmin);

		//LOCGROUP
		Element locgroup = (Element)the_DOC.createElement("locgroup");
		locgroup.appendChild(the_DOC.createTextNode((""+0)));
		featloc.appendChild(locgroup);

		//RANK
		Element rank = (Element)the_DOC.createElement("rank");
		rank.appendChild(the_DOC.createTextNode((""+0)));
		featloc.appendChild(rank);

		//STRAND
		Element strand = (Element)the_DOC.createElement("strand");
		if(tmp_span.isForward()){
			strand.appendChild(the_DOC.createTextNode("1"));
		}else{
			strand.appendChild(the_DOC.createTextNode("-1"));
		}
		featloc.appendChild(strand);

		//FMAX
		Element fmax = (Element)the_DOC.createElement("fmax");
		fmax.appendChild(the_DOC.createTextNode((""+localMax)));
		featloc.appendChild(fmax);
		return featloc;
	}

	public void fillInBlankNames(String the_accName){
		//GIVE NAMES TO BLANK EXONS

		//CHECK FOR UNNAMED EXONS WHICH HAVE NAMED COPIES ELSEWHERE
		for(int i=0;i<m_RenExonList.size();i++){
			RenEx rei = (RenEx)m_RenExonList.get(i);
			if(rei.getName()==null){
				//CHECK BEFORE
				for(int j=0;j<m_RenExonList.size();j++){
					RenEx rej = (RenEx)m_RenExonList.get(j);
					if(i==j){
						//SKIP
					}else if(rei.getSpan().toString().equals(rej.getSpan().toString())){
						//HAVE SAME SPAN
						if(rej.getName()!=null){
							rei.setName(rej.getName());
						}
					}
				}
			}
		}

		//CALCULATE NEW ORDINAL NAMES FOR STILL UNNAMED EXONS
		int blankCnt = 0;
		int maxExonOrd = 0;
		int llfo = 0;
		for(int i=0;i<m_RenExonList.size();i++){
			RenEx re = (RenEx)m_RenExonList.get(i);
			if(re.getName()==null){
				blankCnt++;
			}else{
				int exonOrd = 0;
				int indx = re.getName().indexOf(":");
				if(indx>0){
					String exOrdStr = re.getName().substring(indx+1).trim();
					if(exOrdStr.startsWith("temp")){
						exonOrd = -1;
					}else{
						try{
							exonOrd = Integer.decode(exOrdStr).intValue();
						}catch(Exception ex){
						}
					}
				}
				re.setOrdinal(exonOrd);
			}
		}
		if(blankCnt>0){
			//System.out.println("\tHAS <"+blankCnt+"> BLANKS");
			for(int i=1;i<=blankCnt;i++){
				//System.out.println("START LFO");
				int lfo = getLowestFreeOrdinal(llfo);
				//System.out.println("LFO<"+lfo+">");
				for(int j=0;j<m_RenExonList.size();j++){
					RenEx re = (RenEx)m_RenExonList.get(j);
					if(re.getOrdinal()==0){
						re.setOrdinal(lfo);
						llfo = lfo;
						re.setName(the_accName+":"+lfo);
						j = m_RenExonList.size();
					}
				}
			}
		}
		//SORT
	}

	public int getLowestFreeOrdinal(int the_lastlowestfreeordinal){
		//int ord = 1;
		int ord = the_lastlowestfreeordinal+1;
		boolean found = true;
		while(found){
			found = false;
			for(int j=0;j<m_RenExonList.size();j++){
				RenEx re = (RenEx)m_RenExonList.get(j);
				//System.out.println("\tORDLOOKINGFOR<"+ord
				//		+"> CURORD<"
				//		+re.getOrdinal()+">");
				if(ord==re.getOrdinal()){
					found = true;
					ord++;
					j=m_RenExonList.size();
				}
			}
			if(found==false){
				return ord;
			}
		}
		return ord;
	}

	private void DisplayRenExon(){
		for(int i=0;i<m_RenExonList.size();i++){
			RenEx re = (RenEx)m_RenExonList.get(i);
			//System.out.println("\tEXON<"+re.getName()
			//		+"> SPAN<"+re.getSpan()+">");
		}
	}

	private String getRenExonName(Span exonSpan){
		if(m_RenExonList==null){
			return null;
		}
		for(int i=0;i<m_RenExonList.size();i++){
			RenEx re = (RenEx)m_RenExonList.get(i);
			Span sp = re.getSpan();
			if(sp.toString().equals(exonSpan.toString())){
				if(re.getName()!=null){
					return re.getName();
				}else{
					return "MANUFACTURED_NAME";
				}
			}
		}
		return null;
	}

	public class RenEx{
		private String m_name = null;
		private Span m_span = null;
		private int m_ordinal = 0;

		public RenEx(String the_name,Span the_span){
			m_name = the_name;
			m_span = the_span;
		}

		public void setName(String the_name){
			m_name = the_name;
		}

		public String getName(){
			return m_name;
		}

		public Span getSpan(){
			return m_span;
		}

		public void setOrdinal(int the_ordinal){
			m_ordinal = the_ordinal;
		}

		public int getOrdinal(){
			return m_ordinal;
		}

		public String toString(){
			return ("NM<"+m_name+"> SP<"+m_span+">");
		}
	}
}

//Ribosome r = new Ribosome();
//public String getAminoAcid(String the_codon,int the_TransType);

