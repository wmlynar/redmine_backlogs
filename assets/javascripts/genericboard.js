RB.$(function() {

    /**
     * bind the "Select board" select box
     */
    RB.$('#select_board').change(function(e) {
        document.location.href = RB.urlFor('genericboards', {id: this.value});
    });

});