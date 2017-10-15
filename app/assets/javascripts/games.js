// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(document).ready(function(){

    $('#g-search').on('change', function(){
        $.get('/games', $(this).serialize(), null, 'script');
    });

});