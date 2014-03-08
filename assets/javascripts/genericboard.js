RB.$(function() {
    var board = RB.Factory.initialize(RB.Genericboard, RB.$('#taskboard'));

    /**
     * bind the "Select board" select box
     */
    RB.$('#select_board').change(function(e) {
        document.location.href = RB.urlFor('genericboards', {id: this.value});
    });

    /* make taskbord swimlane header floating */
    RB.$("#board_header").verticalFix({
        delay: 50
    });


});


/***************************************
  TASKBOARD
***************************************/

RB.Genericboard = RB.Object.create({

  initialize: function(el){
    var j = RB.$(el);
    var self = this; // So we can bind the event handlers to this object

    self.$ = j;
    self.el = el;

    // Associate this object with the element for later retrieval
    j.data('this', self);

    // Initialize column widths
    self.colWidthUnit = RB.$(".swimlane").width();
    console.log('cwunit', self.colWidthUnit);
    self.defaultColWidth = 2;
    self.loadColWidthPreference();
    self.updateColWidths();
    RB.$("#col_width input").bind('keyup', function(e){ if(e.which==13) self.updateColWidths(); });

    //initialize mouse handling for drop handling
    j.bind('mousedown.taskboard', function(e) { return self.onMouseDown(e); });
    j.bind('mouseup.taskboard', function(e) { return self.onMouseUp(e); });

    // Initialize task lists, restricting drop to the story
    var tasks_lists =j.find('.story-swimlane');
    if (!tasks_lists || !tasks_lists.length) {
      alert("There are no task states. Please check the workflow of your tasks tracker in the administration section.");
      return;
    }

    var sortableOpts = {
      placeholder: 'placeholder',
      distance: 3,
      helper: 'clone', //workaround firefox15+ bug where drag-stop triggers click
      start: self.dragStart,
      stop: function(e, ui) {return self.dragStop(e, ui);},
      update: self.dragComplete
      //revert: true, //this interferes with capybara test timings. This braindead stupid jquery-ui issues dragStop after all animations are finished, no way to save the drag result while animation is in progress.
      //scroll: true
    };

    //initialize the cells (td) as sortable
    if (RB.permissions.update_tasks) {
      j.find('.story-swimlane .list').sortable(RB.$.extend({
        connectWith: '.story-swimlane .list'
        }, sortableOpts));
    }

    // Initialize each task in the board
    j.find('.task').each(function(index){
      var task = RB.Factory.initialize(RB.Generic, this); // 'this' refers to an element with class="task"
    });
    // Initialize each story in the board
    j.find('.rowelement').each(function(index){
      var task = RB.Factory.initialize(RB.Generic, this); // 'this' refers to an element with class="task"
    });

    // add new buttons
    j.find('#generics td').hover(function(e){self.showAddButton(this, e);}, function(e){self.hideAddButton(this, e);});

  },

  showAddButton: function(target, e)  {
    var me = this;
    var btn = RB.$('#add_button_template').children().first().clone();
    RB.$(target).append(btn);
    btn.click(function(e) { //this is the button, target is the cell
        console.log('Adding something in', target, me);
    })
  },
  hideAddButton: function(target, e)  {
    RB.$(target).find('.addbutton').unbind().remove();
  },

  onMouseUp: function(e) {
      //re-enable all cells deferred
      setTimeout(function(){
        RB.$(':ui-sortable').sortable('enable');
      }, 10);
  },
  /**
   * can drop when:
   *  RB.constants.task_states.transitions['+c+a ???'][from_state_id][to_state_id] is acceptable
   *
   *  and target story can accept this task:
   *    story and task are same project
   *    or task is in a subproject of story? and redmine cross-project relationships are ok
   */
  onMouseDown: function(e) {
    // find the dragged target
    var el = RB.$(e.target).parents('.model.issue'); // .task or .impediment
    if (!el.length) return; //click elsewhere

    var status_id = el.find('.meta .status_id').text();
    var user_status = el.find('.meta .user_status').text();
    var tracker_id = el.find('.meta .tracker_id').text();
    var old_project_id = el.find('.meta .project_id').text();
    var old_story_id = el.find('.meta .story_id').text();

    //disable non-droppable cells
    RB.$('.ui-sortable').each(function() {
      var new_project_id = this.getAttribute('-rb-project-id');
      var new_story_id = $(this).closest('tr').find('div.story a').text();
      // check for project
      //sharing, restrictive case: only allow same-project story-task relationship
      if (new_project_id != old_project_id && old_story_id != new_story_id) {
        RB.$(this).sortable('disable');
        return;
      }

      // check for status
      var new_status_id = this.getAttribute('-rb-status-id');
      // allow dragging to same status to prevent weird behavior
      // if one tries drag into another story but same status.
      if (new_status_id == status_id) { return; }

      if (RB.constants.task_states) {
        var states = RB.constants.task_states['transitions'][tracker_id][user_status][status_id];
        if (!states) { states = RB.constants.task_states['transitions'][tracker_id][user_status][RB.constants.task_states['transitions'][tracker_id][user_status]['default']]; }
        if (RB.$.inArray(String(new_status_id), states) < 0) {
          //workflow does not allow this user to put the issue into this new state.
          RB.$(this).sortable('disable');
          return;
        }
      }

    }); //each

    el = RB.$(e.target).parents('.list'); // .task or .impediment
    if (el && el.length) el.sortable('refresh');
  },

  dragComplete: function(event, ui) {
    if (!ui.sender) { // Handler is triggered for source and target. Thus the need to check.
      ui.item.data('this').saveDragResult();
    }
  },

  dragStart: function(event, ui){
    if (RB.$.support.noCloneEvent){
      ui.item.addClass("dragging");
    } else {
      // for IE
      ui.item.addClass("dragging");
      ui.item.draggable('enabled');
    }
  },

  dragStop: function(event, ui){
    this.onMouseUp(event);
    if (RB.$.support.noCloneEvent){
      ui.item.removeClass("dragging");
    } else {
      // for IE
      ui.item.draggable('disable');
      ui.item.removeClass("dragging");
    }
  },

  handleAddNewImpedimentClick: function(event){
    if (event.button > 1) return;
    var row = RB.$(this).parents("tr").first();
    RB.$('#taskboard').data('this').newImpediment(row);
  },

  handleAddNewTaskClick: function(event){
    if (event.button > 1) return;
    var row = RB.$(this).parents("tr").first();
    RB.$('#taskboard').data('this').newTask(row);
  },

  loadColWidthPreference: function(){
    var w = RB.UserPreferences.get('taskboardColWidth');
    if (!w) { // 0, null, undefined.
      w = this.defaultColWidth;
      RB.UserPreferences.set('taskboardColWidth', w);
    }
    RB.$("#col_width input").val(w);
  },

  newImpediment: function(row){
    var impediment = RB.$('#impediment_template').children().first().clone();
    row.find(".list").first().prepend(impediment);
    var o = RB.Factory.initialize(RB.Impediment, impediment);
    o.edit();
  },

  newTask: function(row){
    var task = RB.$('#task_template').children().first().clone();
    row.find(".list").first().prepend(task);
    var o = RB.Factory.initialize(RB.Task, task);
    o.edit();
  },

  updateColWidths: function(){
    var w = parseInt(RB.$("#col_width input").val(), 10);
    if (!w || isNaN(w)) { // 0,null,undefined,NaN.
      w = this.defaultColWidth;
    }
    RB.$("#col_width input").val(w);
    RB.UserPreferences.set('taskboardColWidth', w);
    RB.$(".swimlane").width(this.colWidthUnit * w).css('min-width', this.colWidthUnit * w);
  }
});
