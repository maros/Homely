"use strict";
$( document ).ready(function() {
    function setDashboardHeight() {
        $('.container .row').each(function() {
            var max_height = 0;
            $(this).find('.dashboard-box').each(function() {
                var height = $(this).innerHeight();
                max_height = Math.max(height,max_height);
            });
            if (max_height > 0) {
                $(this).find('.dashboard-box').css({height: max_height });
            }
        });
    }

    $(window).on('resize',setDashboardHeight).trigger('resize');
});
