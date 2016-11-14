$(document).ready(function(){

    $('#t-search').on('input', function(){
        $.get('/titles', $(this).serialize(), null, 'script');
    });

});