package org.gmod.chado.ix;

/**
  
  IxReadSax
  
  major rewrite of org.gmod.chado.chadxtogame.ChadoSaxReader 
  and perl equivalent (needed before chadxtogame was ready).

  @author: d.gilbert
*/

import org.xml.sax.helpers.DefaultHandler;
import org.xml.sax.*;
import org.xml.sax.Attributes;
import org.xml.sax.SAXException;

import javax.xml.parsers.*;
import java.util.*;
import java.io.*;

import org.gmod.chado.ix.Debug;

public class IxReadSax extends DefaultHandler 
//was ReadSax .. ChadoSaxReader
{

	public static void main(String args[]) {
		String fn = "../XORT/Config/dump_gene_local_id.xml";
		if (args.length>0) fn= args[0];
		IxReadSax ird = new IxReadSax();
    Debug.println(ird.getClass().getName()+" parsing <"+fn+">");
		ird.parse(fn);
		IxFeat root = ird.getRoot();
		if (root==null) System.out.println("Null root: "+ird.ROOT_NODE);
		else root.printObj(System.out, 0);
	}

	public IxReadSax(){
		super();
		init();
		// read properties file, with fields, skip-fields, ..
	}

	public void parse(String systemId){ parse(new InputSource(systemId)); }
	public void parse(InputStream bytes){ parse(new InputSource(bytes)); }
	public void parse(Reader reader){ parse(new InputSource(reader)); }
    
	public void parse(InputSource source){
		try {
			SAXParserFactory sFact = SAXParserFactory.newInstance();
			parser = sFact.newSAXParser();
			parser.parse(source,this);
		}catch(SAXException e){
			Debug.errprintln("SAXException "+e.getMessage());
			Exception emx= e.getException(); //e.printStackTrace();
			if (emx!=null) emx.printStackTrace();
		}catch(ParserConfigurationException e){
			Debug.errprintln("ParserConfigurationException ");
			e.printStackTrace();
		}catch(IOException e){
			Debug.errprintln("IOException ");
			e.printStackTrace();
		}
	}

  public IxObject getById(String id) {
    return (IxObject)idhash.get(id);
    }
    
	public final IxFeat getTopNode(){ return getRoot(); }
	public IxFeat getRoot(){
		return (IxFeat)keyvals.get(ROOT_NODE); //m_CurrChado;
	}

    // possibly properties setting
  public final static String ROOT_NODE = "chado";
    // read from properties
  public static String[] skipKeys= {
    "locgroup", 
    "timelastmodified", "timeaccessioned", 
    "residues", "md5checksum", 
    "rank", "prank", "strand",
    "is_nend_partial", "is_nbeg_partial",
    "min", "max",
    "is_current", "is_analysis",
    "evidence_id",
    "organism_id", 
    "_appdata",
    };
    
  Properties props;  
  SAXParser parser;
  java.util.Stack featstack= new java.util.Stack();
  java.util.Stack genfeatstack= new java.util.Stack();
  java.util.Stack elstack= new java.util.Stack();
  HashMap idhash= new HashMap();
  HashMap keyvals= new HashMap();
	HashSet skipkeys= new HashSet();
  IxFeat curfeat, curgenfeat;
  String skipkids= null;
  String parel= null;
    
  private void init() {
     props= new Properties();
     try {
      File f= new File(ROOT_NODE+".properties"); // really want to use classpath
      if (!f.exists()) f= new File(ROOT_NODE+".props");
      if (!f.exists()) f= new File(ROOT_NODE+".conf");
      if (f.exists()) props.load( new FileInputStream(f));
      }
     catch (Exception e) { }
    //if (!keyvals.containsKey("tag")) keyvals.put("tag", "IxReadSax");
    
    String[] skips= skipKeys;
    if (props.get("skip") instanceof String[])  
      skips= (String[])props.get("skip");  
    skipkeys= new HashSet(Arrays.asList(skips));
    
    //? dont need dummy root
    keyvals.put(ROOT_NODE, new IxFeat(this, new String[] { "tag", ROOT_NODE}));
    
    //# 	$self->{views}= [ 'text/asn1', 'text/acode', 'text/xml;game' ]
    //# 		unless (exists $self->{views} );
    }

  // -- char values handler -- keep one for each nested element
  HashMap chvals= new HashMap();
  private String chsave=""; 
  private boolean chhas;
  private String chshow() { return chsave; }
  private String chuse() { chhas=false; return chsave; }  
  //private boolean chhas() { return chhas; }  

  private void chstart(String elname) { 
    StringBuffer sb= (StringBuffer)chvals.get(elname);
    if (sb!=null) sb.setLength(0); 
    chsave=""; 
    }
 
  private boolean chend(String elname) { 
    chsave= chcheckval( chgetbuf(elname));
    chhas= (chsave.length()>0);
    return chhas;
    }

    // to be really precise about chars,  use full xpath not el name
  private StringBuffer chgetbuf(String elname) {
    StringBuffer sb= (StringBuffer)chvals.get(elname);
    if (sb==null) { sb= new StringBuffer(); chvals.put(elname,sb); }
    return sb;
    }
  
  private String chcheckval(StringBuffer sb) { 
    int wb= -1, we= -1, se=  sb.length()-1;
    for (int i= se; i>=0; i--) {
      boolean iswt= Character.isWhitespace(sb.charAt(i));
      if (iswt) { wb= i; if (we<0) we= i; }
      if ((!iswt || i==0) && (we>0 && we>wb)) {
        if (we < se && wb > 0) { sb.setCharAt(wb,' '); wb++; }
        sb.delete(wb,we);
        we= -1; wb= -1;
        }
      }  
    return sb.toString().trim(); 
    }

  boolean chhasval(StringBuffer sb) {
    return (chcheckval(sb).length()>0);
    }
         
	public void characters(char[] ch,int start,int length){
		chgetbuf(parel).append( ch, start,length);
	  }
 
 
  final boolean iselem(String p, String e) { return (p.indexOf( e) >= 0); }
  final boolean iselemp(String p, Object e) {
    String s= "|"+e+"|";  return (p.indexOf(s) >= 0);
    }


	public void startElement (String namespaceUri, String localName,
		String elname, Attributes attributes) throws SAXException {

    String elpar= this.parel;
    if (elpar!=null) elstack.push(elpar);
		this.parel= elname;
    if (skipkids!=null) return;
    
		chstart(elname);  
    boolean nada= false;
    String elnamepp= "|"+elname+"|";
    
		//MAIN FEATURES

    if ( iselem("|"+ROOT_NODE+"|feature|feature_evidence|analysis|cvterm|cv|pub|organism|", elnamepp) ) { 

      String atid = attributes.getValue("id");
      // "ref" is used sometimes for feature? if "id" is null
      IxFeat ft = new IxFeat( this, new String[] { "tag", elname, "id", atid } );
      keyvals.put(elname, ft);
      curgenfeat= ft;  
      genfeatstack.push(ft);
      idhash.put(atid,ft);
      
      if ( iselem("|"+ROOT_NODE+"|feature|feature_evidence|", elnamepp) ) { 
        curfeat= ft;
        featstack.push(ft);
        }
        
      if ("feature".equals(elname) && "srcfeature_id".equals(elpar)) {
        keyvals.put("srcfeature_id", atid);
        }  
      }
   
    // what to do w/ other _id entries: 
    // feature_id srcfeature_id - used in featureloc
    // subjfeature_id objfeature_id - used in feature_relationship
    // evidence_id - in feature_evidence
    // cv_id in cv ; cvterm_id in cvterm ; pkey_id in pkey
    // type_id in various ?
    // analysis_id - in analysis ; synonym_id - in synonym 
    // organism_id - in organism ; pub_id in pub ; dbxref_id in dbxref
    //  
    else if ("feature_id".equals(elname)) {
      if ("featureloc".equals(elpar)) skipkids= "feature_id"; 
      }
      
    else if ("featureloc".equals(elname)) {
      IxSpan span = new IxSpan( this,  new String[]{ "tag", elname, "src", "" } );
      curfeat.put("span",span); // only one per featloc ?
      }

    else if ( iselem("|dbname|accession|pkey_id|pval|pub_id|", elnamepp) ) { 
		  keyvals.remove(elname); // require val
			}

      // new Attributes w/ ids ? == feature_relationship, synonym
    else if ( iselem("|dbxref|dbxref_id|featureprop|", elnamepp) ) { 
      String atid = attributes.getValue("id");
      IxAttr attr = new IxAttr( this, new String[] { "tag", elname } );
      if (atid != null) { 
        attr.put( "id" , atid); 
        idhash.put( atid, attr);
        }
      keyvals.put(elname, attr); 
			}
		
		else {
		  nada= true;
		  }  

	}
	
	

	public void endElement(String namespaceUri,String localName,
				String elname)
	{
    this.parel= (elstack.isEmpty())? null: (String)elstack.pop();
    String elpar= this.parel;

    if ( skipkids != null ) {
      if (  skipkids.equals(elname) ) { skipkids=null; }
      else { return; }
      }

    boolean hasval= chend(elname);
    String elnamepp= "|"+elname+"|";
    boolean nada= false;
    
	  //SINGLE PARAMETER ELEMENTS
 
    if ( iselem("|uniquename|organism_id|rawscore|", elnamepp) ) { 
      if (hasval && !skipkeys.contains(elname))
        curfeat.put( elname, chuse());
			}
			
    else if ("type_id".equals(elname)) {
 		  if (hasval && !"contains".equals(chshow())) {
		    if ("feature_relationship".equals(elpar)) {
		      //## skip
		      }
		    else if ( iselemp("|pub|feature|", curgenfeat.get("tag") ) ) {
 		      curgenfeat.put( elname, chuse());
 		      }
 		    else {
 		      Debug.errprintln( "UNKNOWN parent for "+elname+" = "+chshow());  
 		      }
 		    }
      }

    else if ("residues".equals(elname)) {
      if (hasval && !skipkeys.contains(elname)) {
        curfeat.put( elname, chuse());
        curfeat.put( "residuetype", "cdna");
       }
      }

    else if ( iselem("|name|miniref|program|programversion|", elnamepp) ) { 
      if (hasval && curgenfeat!=null) {
  	    curgenfeat.put( elname,chuse());
        }
      }
 		  
    else if ("cvname".equals(elname)) {
      if (hasval && keyvals.containsKey("cv")) {
        ((IxFeat)keyvals.get( "cv")).put( elname, chuse());
       }
      }
      
    else if ("cv_id".equals(elname)) {
      if (hasval && keyvals.containsKey("cvterm")) {
        ((IxFeat)keyvals.get( "cvterm")).put( elname, chuse());
       }
      }

//## 		//PUTTING PARAMETERS INTO OBJECTS
//## IxFeat set:
//##		/^($ROOT_NODE|feature|analysis|cvterm|cv|pub|organism)$/ 

    else if ( iselem("|organism|pub|cvterm|cv|analysis|", elnamepp) ) { 
      IxFeat ft= (IxFeat) keyvals.remove(elname);
      genfeatstack.pop();
			
			//##  - push id of this into elpar value
      if (! chhasval(chgetbuf(elpar)) ) {
        chgetbuf(elpar).append(ft.get("id"));
        } 
        
      getRoot().add(ft);
      curgenfeat= (genfeatstack.isEmpty())? null : (IxFeat)genfeatstack.peek();
      }

 	  else if ( iselem("|feature|feature_evidence|", elnamepp) ) {
      IxFeat ft= (IxFeat) featstack.pop();
      IxFeat parft= (featstack.isEmpty())? null : (IxFeat) featstack.peek(); 
      if (parft!=null) parft.add( ft);
      keyvals.remove(elname);
      curfeat= parft;
      genfeatstack.pop();
      curgenfeat= (genfeatstack.isEmpty())? null : (IxFeat) genfeatstack.peek();
      }

  	//FEATURELOC

    else if ( iselem("|nbeg|nend|srcfeature_id|", elnamepp) ) {
 		  String val= chuse();
 		  //boolean hasval= chhas();
 		  if (!hasval) {
 		    val= (String) keyvals.get(elname);
 		    if (val!=null) val= chcheckval( new StringBuffer(val));
        if (val!=null && val.length()>0) hasval= true;
 		    }
 		    
 		  if (hasval) {
 		    IxSpan span= (IxSpan)curfeat.get("span");
 		    String nm= ("srcfeature_id".equals(elname)) ? "src" : elname;
        span.put( nm, val);
 		    }
      }
      
    else if ("featureloc".equals(elname)) {
 		  IxSpan span= (IxSpan)curfeat.remove("span");
 		  if (span!=null) curfeat.addloc(span);
      }
   
  		//ATTRIB
    else if ("dbxref_id".equals(elname)) {
 		  IxAttr attr= (IxAttr) keyvals.remove(elname);
 		  if (hasval) attr.setattr( chuse() );
 		  if ( curfeat != null )  curfeat.addattr( attr);  		  
      }
    else if ("dbxref".equals(elname)) {
 		  IxAttr attr= (IxAttr) keyvals.remove(elname);
 		  String db= (String)keyvals.remove("dbname");
 		  String acc= (String)keyvals.remove("accession");
 		  String dbid= (db!=null) ? db+":"+acc : acc;
 		  attr.setattr( dbid); 
 		  IxAttr dbxattr= (IxAttr) keyvals.get("dbxref_id");
 		  if (dbxattr!=null) dbxattr.setattr( attr);
 		  else if ( curfeat != null )  curfeat.addattr( attr);  		 		    
      }
      
    else if ("featureprop".equals(elname)) {
 		  IxAttr attr= (IxAttr) keyvals.remove(elname);
  	  Object val;
  	  if ( (val= keyvals.remove("pval"))!=null ) attr.setattr(val);
  	  if ( (val= keyvals.remove("pkey_id"))!=null ) attr.put("pkey_id", val);
  	  if ( (val= keyvals.remove("pub_id"))!=null ) attr.put("pub_id", val);
 		  if ( curfeat != null )  curfeat.addattr( attr);  		  
      }

 		//ATTRIB FIELDS
    else if ( iselem("|dbname|accession|pkey_id|pval|pub_id|", elnamepp) ) {
 		  if (hasval) keyvals.put(elname,chuse());
      }
  
    else {
      nada= true;
      }
		
	// dgg - check for left over data
	// collect unused elnames and chars here..
  //elcount.get(elname)++ # debug only
	
  if ( nada && !skipkeys.contains(elname) ) {  
    getRoot().put("unused_"+elname , elname); //?
	  if (hasval) {
      IxAttr attr = new IxAttr( this, new String[] { "tag", elname } );
 	    attr.setattr( chuse() );
  	  curgenfeat.addattr( attr );
	    //Debug.println(  "# unused <"+elname+">"+chshow()+"</"+elname+">");
	    }
	  }	
	  
	  
	}


}






