RB.$(function() {

    /**
     * bind the "Select board" select box
     */
    RB.$('#select_board').change(function(e) {
        document.location.href = RB.urlFor('genericboards', {id: this.value});
    });

    //fixup width of cells #FIXME make this configurable like taskboard
    var _width = 240;
    RB.$(".swimlane").width(_width).css('min-width', _width);

    /* make taskbord swimlane header floating */
    RB.$("#board_header").verticalFix({
        delay: 50
    });


});