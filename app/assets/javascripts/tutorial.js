$(document).ready(function(){
    var tutorial = $('#tutorial-page');

    if(tutorial.length === 0){
        return;
    }

    function showTutorialMode(mode){
        var checkoutMode = mode === 'checkout';
        var returnMode = mode === 'return';
        var searchMode = mode === 'search';

        tutorial.attr('data-tutorial-mode', mode);
        $('.tutorial-checkout-view').toggle(checkoutMode);
        $('.tutorial-return-view').toggle(returnMode);
        $('.tutorial-search-view').toggle(searchMode);
        $('#tutorial-checkout-mode').toggleClass('btn-primary', checkoutMode).toggleClass('btn-default', !checkoutMode);
        $('#tutorial-return-mode').toggleClass('btn-primary', returnMode).toggleClass('btn-default', !returnMode);
        $('#tutorial-search-mode').toggleClass('btn-primary', searchMode).toggleClass('btn-default', !searchMode);
    }

    $('#tutorial-checkout-mode').click(function(){
        showTutorialMode('checkout');
    });

    $('#tutorial-return-mode').click(function(){
        showTutorialMode('return');
    });

    $('#tutorial-search-mode').click(function(){
        showTutorialMode('search');
    });

    $('#tutorial-prev').click(function(){
        showTutorialMode(tutorial.attr('data-tutorial-mode') === 'search' ? 'return' : 'checkout');
    });

    $('#tutorial-next').click(function(){
        showTutorialMode(tutorial.attr('data-tutorial-mode') === 'checkout' ? 'return' : 'search');
    });
});