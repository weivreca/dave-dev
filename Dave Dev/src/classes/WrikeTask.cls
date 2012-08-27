public with sharing class WrikeTask {

	class FilteredList {
		public Integer tLast;
		public Tasks[] Lists;
		
		public FilteredList (Integer tlast, Tasks[] t) {
			this.tLast = tlast;
			this.Lists = t;	
		}
		
	}
	
	class Tasks {
		public Integer id;
		public String title;
		public String description;
		public String authorUid;
		public String createdDate;
		public String whoChanged;
		public String lastUpdatedDate;
		public String type;
		public Boolean status;
		public Boolean importance;
		public Integer priority;
		public String startDate;
		public String dueDate;
		public String duration;
		public Integer attachmentsCount;
		public Integer commentsCount;
		public Users [] responsibleUsers;
		public Users [] sharedUsers;
		public Folders[] parents;
		public String recurenceTemplate;
		public Predecessors[] predecessor;
		public Successors[] successors;
		
		public Tasks (Integer i,String t,String d,String a,String cd,String wc,
				String lup,String ty,Boolean s,Boolean im,Integer p,String sd,
				String dd,String du,Integer att,Integer cc,Users[] ru,Users[] su,
				Folders[] pa,String rt,Predecessors[] pr,Successors[] sr) {
			this.id = i;
			this.title = t;
			this.description = d;
			this.authorUid = a;
			this.createdDate = cd;
			this.whoChanged = wc;
			this.lastUpdatedDate = lup;
			this.type = ty;
			this.status = s;
			this.importance = im;
			this.priority = p;
			this.startDate = sd;
			this.dueDate = dd;
			this.duration = du;
			this.attachmentsCount = att;
			this.commentsCount = cc;
			this.responsibleUsers = ru;
			this.sharedUsers = su;
			this.parents = pa;
			this.recurenceTemplate = rt;
			this.predecessor = pr;
			this.successors = sr;
		}
		
	}
	
	class Users {
		public String id;
		
		public Users (String i) {
			this.id = i;
		}
	}
	
	class Folders {
		public String id;
		
		public Folders (String i) {
			this.id = i;
		}
	}
	
	class Predecessors {
		public Integer id;
		
		public Predecessors (Integer i) {
			this.id = i;
		}
	}
	
	class Successors {
		public Integer id;
		
		public Successors (Integer i) {
			this.id = i;
		}
	}
	
}