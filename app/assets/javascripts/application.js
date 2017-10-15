// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require bootstrap-sprockets
//= require_tree ../../../vendor/assets/javascripts
//= require_tree .

var bc_regex = /^[a-z0-9]{7,13}$/i;

const DEFAULT_ERROR = 'Something nasty occurred. Write down what you did for Mojo Jojo and try again.';

$(document).ready(function(){

    $.ajaxSetup({
        headers: {
            clientOffset: ((new Date()).getTimezoneOffset() / 60)
        }
    });

    setTimeout(pollStatus, 0);

    $('#suggest-btn').click(function(){
        $(this).hide();
        $('#suggest-form').show();
        $('#suggest-title').focus();
    });

    $('#cancel-suggest').click(function(){
        hideSuggest();
    });

    $('#suggest-title').keypress(function(e){
        var _me = $(this);
        _me.parent().removeClass('has-error');
        if(e.which.toString() == "13"){
            postSuggestion();
        }
    });

    $('#save-suggest').click(function(){
        postSuggestion();
    });

});

function pollStatus(){
    $.get('/status').success(function(response){
        $('#total-games').text(response.total_games);
        $('#open-checkouts').text(response.open_checkouts);
        $('#longest-open-checkout').text(response.longest_open_checkout);

        setTimeout(pollStatus, 15000);
    });
}

function hideSuggest(){
    $('#suggest-form').hide().removeClass('has-error');
    $('#suggest-btn').show();
    $('#suggest-title').val('');
}

/*
* Taken from typeahead.js examples.
* https://github.com/twitter/typeahead.js/blob/master/doc/jquery_typeahead.md
* */
function substringMatcher(strs) {
    return function findMatches(q, cb) {
        // an array that will be populated with substring matches
        var matches = [],
        // regex used to determine if a string contains the substring `q`
            substrRegex = new RegExp(q, 'i');

        // iterate through the pool of strings and for any string that
        // contains the substring `q`, add it to the `matches` array
        $.each(strs, function(i, str) {
            if (substrRegex.test(str)) {
                matches.push(str);
            }
        });

        cb(matches);
    };
}

function postSuggestion(){
    var input = $('#suggest-title');
    if(input.val().length > 0) {
        $.ajax({
            url: '/suggest',
            method: 'post',
            data: {title: input.val()},
            success: function (response) {
                if (response.title) {
                    $.notify('Thanks for suggesting "' + response.title + '"!');
                }
            },
            complete: function () {
                hideSuggest();
            }
        });
    } else {
        input.parent().addClass('has-error');
    }
}