$(document).ready(function(){

    $('#p-search').on('input', function(){
        $.get('/publishers', $(this).serialize(), null, 'script');
    });

});