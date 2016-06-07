/**************************************
  EPIC
***************************************/

RB.EpicEB = RB.Object.create(RB.Issue, {

  initialize: function(el){
    var j;  // This ensures that we use a local 'j' variable, not a global one.

    this.$ = j = RB.$(el);
    this.el = el;

    // Associate this object with the element for later retrieval
    j.data('this', this);

    if (RB.permissions.create_epics) {
      j.delegate('.editable', 'click', this.handleClick);
    }
  },

  afterCreate: function(data, textStatus, xhr){
    var result = RB.Factory.initialize(RB.Model, data);
    this.refresh(result);

    /* Remove unused field */
    this.$.find('.tracker_id').first().remove();
    this.$.find('.status_id').first().remove();
    this.$.find('.meta').first().remove();
    this.$.find('.add_new').bind('click', RB.Epicboard.handleAddNewStoryClick);
    this.$.parents('tr').attr('id', 'swimlame-' + result.$.attr('id'));
    this.$.parents('tr').attr('_rb_parent_id', result.$.attr('id'));
  },

  cancelEdit: function(obj){
    this.endEdit();
    if (typeof obj == 'undefined') {
        obj = this;
    }
    if(this.isNew()){
      this.$.hide('blind');
    }

    /* Remove row added to stories table */
    this.$.parents('tr').remove();
  },

  beforeSave: function(){
    var c = this.$.find('select.assigned_to_id').find(':selected').attr('color');
    var c_light = this.$.find('select.assigned_to_id').find(':selected').attr('color_light');
    // Only change color of task if assigned_to_id has a selected user/group
    if(c!=undefined){
      this.$.css('background-color', c);
      this.$.css('background', '-webkit-gradient(linear, left top, left bottom, from('+c_light+'), to('+c+'))');
      this.$.css('background', '-moz-linear-gradient(top, '+c_light+', '+c+')');
      this.$.css('filter', 'progid:DXImageTransform.Microsoft.Gradient(Enabled=1,GradientType=0,StartColorStr='+c_light+',EndColorStr='+c+')');
    }
  },

  editorDisplayed: function(dialog){
    dialog_bgcolor=this.$.css('background-color');
    dialog_bg=this.$.css('background-image');
    if(dialog_bgcolor=='initial'||dialog_bgcolor=='rgba(0, 0, 0, 0)'||dialog_bgcolor=='transparent'){
      // Chrome could not handling background-color css when use -webkit-gradient.
      if(dialog_bg){
        dialog.parents('.ui-dialog').css('background', dialog_bg);
      } else {
        dialog.parents('.ui-dialog').css('background', '-webkit-gradient(linear, left top, left bottom, color-stop(0%,#c9de96), color-stop(44%,#8ab66b), color-stop(100%,#398235))');
        dialog.parents('.ui-dialog').css('background', '-moz-linear-gradient(top, color-stop(25%, green), color-stop(75%, green))');
        dialog.parents('.ui-dialog').css('filter', 'progid:DXImageTransform.Microsoft.Gradient(Enabled=1,GradientType=0,StartColorStr=color-stop(25%, green),EndColorStr=color-stop(75%, green))');
      }
    } else {
      dialog.parents('.ui-dialog').css('background-color', dialog_bgcolor);
    }
  },

  getType: function(){
    return "Epic";
  },

  markIfClosed: function(){
    if(this.$.parents('td').first().hasClass('closed')){
      this.$.addClass('closed');
    } else {
      this.$.removeClass('closed');
    }
  },

  saveDirectives: function(){
    var j = this.$;
    var url;
    var nxt = this.$.next();

    var data = j.find('.editor').serialize() +
               "&view=epic_eb"+
               (this.isNew() ? "" : "&id=" + j.children('.id').text());

    if( this.isNew() ){
      url = RB.urlFor( 'create_epic' );
    } else {
      url = RB.urlFor( 'update_epic', { id: this.getID() } );
      data += "&_method=put";
    }

    return {
      url: url,
      data: data
    };
  }

});
