/* main.js */
$(function () {
  $(document).ready(function() {
    chart = new Highcharts.Chart({
      chart: {
        renderTo: 'commits-chart',
        type: 'column',
        height: 120
      },
      title: {
        text: null
      },
      legend: {
        enabled: false
      },
      xAxis: {
        labels: {
          enabled: false
        }
      },
      yAxis: {
        gridLineWidth: 0,
        labels: {
          enabled: false
        },
        title: {
          text: null
        }
      },
      plotOptions: {
        column: {
          pointPadding: 0.2,
          borderWidth: 0,
          shadow: false
        }
      },
      series: commitsData
    });
  });
});