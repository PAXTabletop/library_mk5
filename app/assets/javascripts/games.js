// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(document).ready(function(){

    $('#g-search input').keydown(function(e) {
        if (e.keyCode == 13) {
            $('#g-search').submit();
        }
    });

    $('#g-search').on('submit', function(event){
        event.preventDefault();
        if($('#home-page').length > 0 && $('#home-page').attr('data-checkout-mode') != 'search'){
            return;
        }
        $.get('/games', $(this).serialize(), null, 'script');
    });

    $('#g-search-loaned').on('change', function(){
    	if (this.checked) {
    		$('#g-search-group').css("display", "inline-block");
    	} else {
    		$('#g-search-group').hide();
    	}
    });

    $('#g-search input[type="checkbox"], #g-search select').on('change', function(){
        $('#g-search').submit();
    });

});
