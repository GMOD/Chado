package basicTest;

import java.io.File;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.hibernate.Criteria;
import org.hibernate.FetchMode;
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.cfg.Configuration;
import org.hibernate.criterion.Restrictions;
import org.hibernate.persister.entity.EntityPersister;

import fr.inra.gmod.chado.Feature;

public class BasicTest {

	public static void testAll(SessionFactory sessionFactory){
		Map metadata = sessionFactory.getAllClassMetadata();
        for (Iterator i = metadata.values().iterator(); i.hasNext(); ) {
            Session session = sessionFactory.openSession();
            try {
                EntityPersister persister = (EntityPersister) i.next();
                String className = persister.getClassMetadata().getEntityName();
                System.out.println("Querying for "+className);
                List result = session.createQuery("from " + className + " c").setMaxResults(10).list();
            } finally {
                session.close();
            }
        }
	}
	
	public static void testSegmentQuery(SessionFactory sessionFactory){
		 Session session = sessionFactory.openSession();
		 
		 //Build a query using the criteria API
		 
		 Criteria crit = session.createCriteria(Feature.class, "feat");
		 
		 
		 //Adding segment parameters
		 crit.createAlias("feat.featurelocFeature", "featLoc");
		 crit.createAlias("featLoc.srcfeature", "srcfeat");
		 crit.add(Restrictions.eq("srcfeat.uniquename", "Os_Os_1"));
		 crit.add(Restrictions.gt("featLoc.fmin", 564))
		     .add(Restrictions.lt("featLoc.fmax", 100000));
		 
		 //Test to add the type or not
		 boolean iWantTypes= true;
		 if (iWantTypes){
			 Object[] types = {"gene","mRNA", "CDS"};
			 crit.createAlias("feat.cvterm","type");
			 crit.add(Restrictions.in("type.name", types));
		 }
		 
		 //execute
		 List l = crit.list();
		 
		 for (Iterator it = l.iterator(); it.hasNext() ; ){
			 Feature f = (Feature) it.next();
			 System.out.println("got the "+ f.getCvterm().getName() +" : "+f.getName()+"");
		 }
		 
		 
	}
	
	/**
	 * Connect to a chado database and check all objects collections
	 * @param args
	 */
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		Configuration cfg = new Configuration();
		cfg.addJar(new File("lib/chado-core-0.003.jar"));
		//cfg.addFile("resources/hibernate.cfg.xml");
		//cfg.addFile("resources/chado/hibernate.properties");
		cfg.configure(new File("resources/hibernate.cfg.xml"));
		SessionFactory sessionFactory = cfg.buildSessionFactory();
		
		//Full test on all entities/tables
		testAll(sessionFactory);
		
		//SegmentQuery
		System.out.println("Testing the Segment Query");
		testSegmentQuery(sessionFactory);
		
	}

}
