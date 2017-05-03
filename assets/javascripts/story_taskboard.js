/**************************************
  IMPEDIMENT
***************************************/

RB.StoryTaskboard = RB.Object.create(RB.Task, {
  
  initialize: function(el){
    var j;  // This ensures that we use a local 'j' variable, not a global one.
    
    this.$ = j = RB.$(el);
    this.el = el;
    
    j.addClass("story"); // If node is based on #task_template, it doesn't have the impediment class yet
    
    // Associate this object with the element for later retrieval
    j.data('this', this);
    
    if (RB.permissions.update_stories) {
      j.delegate('.editable', 'click', this.handleClick);
    }
  },
  
  editDialogTitle: function(){
    return "Edit Story";
  },
				     
  getID: function(){
    return this.$.find('.id .v:first').text();
  },

  // Override saveDirectives of RB.Task
  saveDirectives: function(){
    var url;
    var j = this.$;
      
    var data = j.find('.editor').serialize();

    url = RB.urlFor('update_story', { id: this.getID() });
    data += "&_method=put&taskboard=true";
        
    return {
      url: url,
      data: data
    };
  }

});
