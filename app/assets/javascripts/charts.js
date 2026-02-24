// Chart.js integration for DigiiBudget application

// Portfolio Allocation Chart
function renderPortfolioAllocationChart(elementId, data) {
  const ctx = document.getElementById(elementId);
  if (!ctx) return;
  
  const labels = Object.keys(data).map(type => {
    // Convert investment type to readable format
    switch(type) {
      case 'stocks': return 'Stocks';
      case 'bonds': return 'Bonds';
      case 'mutual_funds': return 'Mutual Funds';
      case 'etfs': return 'ETFs';
      case 'real_estate': return 'Real Estate';
      case 'crypto': return 'Cryptocurrency';
      case 'savings': return 'Savings';
      case 'fixed_deposit': return 'Fixed Deposit';
      case 'pension': return 'Pension';
      default: return type.charAt(0).toUpperCase() + type.slice(1);
    }
  });
  
  const values = Object.values(data).map(item => item.percentage);
  
  const backgroundColors = [
    'rgba(54, 162, 235, 0.8)',
    'rgba(255, 99, 132, 0.8)',
    'rgba(255, 206, 86, 0.8)',
    'rgba(75, 192, 192, 0.8)',
    'rgba(153, 102, 255, 0.8)',
    'rgba(255, 159, 64, 0.8)',
    'rgba(199, 199, 199, 0.8)',
    'rgba(83, 102, 255, 0.8)',
    'rgba(40, 159, 64, 0.8)',
    'rgba(210, 199, 199, 0.8)',
  ];
  
  new Chart(ctx, {
    type: 'doughnut',
    data: {
      labels: labels,
      datasets: [{
        data: values,
        backgroundColor: backgroundColors,
        borderWidth: 1
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          position: 'right',
          labels: {
            boxWidth: 15,
            padding: 15
          }
        },
        tooltip: {
          callbacks: {
            label: function(context) {
              const label = context.label || '';
              const value = context.raw || 0;
              return `${label}: ${value}%`;
            }
          }
        }
      }
    }
  });
}

// Investment Value History Chart
function renderValueHistoryChart(elementId, data) {
  const ctx = document.getElementById(elementId);
  if (!ctx || !data || data.length === 0) return;
  
  const dates = data.map(item => item.date);
  const values = data.map(item => item.value);
  
  new Chart(ctx, {
    type: 'line',
    data: {
      labels: dates,
      datasets: [{
        label: 'Investment Value',
        data: values,
        borderColor: 'rgba(75, 192, 192, 1)',
        backgroundColor: 'rgba(75, 192, 192, 0.2)',
        borderWidth: 2,
        fill: true,
        tension: 0.1
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        x: {
          title: {
            display: true,
            text: 'Date'
          }
        },
        y: {
          title: {
            display: true,
            text: 'Value (K)'
          },
          beginAtZero: true
        }
      }
    }
  });
}

// Spending by Category Chart
function renderSpendingByCategoryChart(elementId, data) {
  const ctx = document.getElementById(elementId);
  if (!ctx) return;
  
  const categories = Object.keys(data);
  const amounts = Object.values(data);
  
  const backgroundColors = [
    'rgba(54, 162, 235, 0.8)',
    'rgba(255, 99, 132, 0.8)',
    'rgba(255, 206, 86, 0.8)',
    'rgba(75, 192, 192, 0.8)',
    'rgba(153, 102, 255, 0.8)',
    'rgba(255, 159, 64, 0.8)',
    'rgba(199, 199, 199, 0.8)',
    'rgba(83, 102, 255, 0.8)',
    'rgba(40, 159, 64, 0.8)',
    'rgba(210, 199, 199, 0.8)',
  ];
  
  new Chart(ctx, {
    type: 'bar',
    data: {
      labels: categories,
      datasets: [{
        label: 'Spending Amount',
        data: amounts,
        backgroundColor: backgroundColors,
        borderWidth: 1
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        y: {
          beginAtZero: true,
          title: {
            display: true,
            text: 'Amount (K)'
          }
        }
      }
    }
  });
}

// Monthly Spending Trend Chart
function renderMonthlySpendingTrendChart(elementId, data) {
  const ctx = document.getElementById(elementId);
  if (!ctx) return;
  
  new Chart(ctx, {
    type: 'line',
    data: {
      labels: data.labels,
      datasets: [{
        label: 'Monthly Spending',
        data: data.values,
        borderColor: 'rgba(255, 99, 132, 1)',
        backgroundColor: 'rgba(255, 99, 132, 0.2)',
        borderWidth: 2,
        fill: true,
        tension: 0.1
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        x: {
          title: {
            display: true,
            text: 'Month'
          }
        },
        y: {
          title: {
            display: true,
            text: 'Amount (K)'
          },
          beginAtZero: true
        }
      }
    }
  });
}

// Budget vs Actual Chart
function renderBudgetVsActualChart(elementId, data) {
  const ctx = document.getElementById(elementId);
  if (!ctx) return;
  
  const categories = data.categories;
  const budgetAmounts = data.budgetAmounts;
  const actualAmounts = data.actualAmounts;
  
  new Chart(ctx, {
    type: 'bar',
    data: {
      labels: categories,
      datasets: [
        {
          label: 'Budget',
          data: budgetAmounts,
          backgroundColor: 'rgba(54, 162, 235, 0.6)',
          borderColor: 'rgba(54, 162, 235, 1)',
          borderWidth: 1
        },
        {
          label: 'Actual',
          data: actualAmounts,
          backgroundColor: 'rgba(255, 99, 132, 0.6)',
          borderColor: 'rgba(255, 99, 132, 1)',
          borderWidth: 1
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        y: {
          beginAtZero: true,
          title: {
            display: true,
            text: 'Amount (K)'
          }
        }
      }
    }
  });
}

// Financial Goals Progress Chart
function renderGoalsProgressChart(elementId, data) {
  const ctx = document.getElementById(elementId);
  if (!ctx) return;
  
  const goalNames = data.map(goal => goal.name);
  const currentAmounts = data.map(goal => goal.current_amount);
  const targetAmounts = data.map(goal => goal.target_amount);
  
  new Chart(ctx, {
    type: 'bar',
    data: {
      labels: goalNames,
      datasets: [
        {
          label: 'Current Amount',
          data: currentAmounts,
          backgroundColor: 'rgba(75, 192, 192, 0.6)',
          borderColor: 'rgba(75, 192, 192, 1)',
          borderWidth: 1
        },
        {
          label: 'Target Amount',
          data: targetAmounts,
          backgroundColor: 'rgba(153, 102, 255, 0.6)',
          borderColor: 'rgba(153, 102, 255, 1)',
          borderWidth: 1
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        y: {
          beginAtZero: true,
          title: {
            display: true,
            text: 'Amount (K)'
          }
        }
      }
    }
  });
}

// Initialize all charts when the document is ready
document.addEventListener('DOMContentLoaded', function() {
  // Check if Chart.js is loaded
  if (typeof Chart === 'undefined') {
    console.error('Chart.js is not loaded. Please include the Chart.js library.');
    return;
  }
  
  // Initialize charts if the elements exist
  if (document.getElementById('portfolio-allocation-chart')) {
    // The data should be provided by the server and made available to JavaScript
    if (typeof portfolioAllocationData !== 'undefined') {
      renderPortfolioAllocationChart('portfolio-allocation-chart', portfolioAllocationData);
    }
  }
  
  if (document.getElementById('value-history-chart')) {
    if (typeof valueHistoryData !== 'undefined') {
      renderValueHistoryChart('value-history-chart', valueHistoryData);
    }
  }
  
  if (document.getElementById('spending-by-category-chart')) {
    if (typeof spendingByCategoryData !== 'undefined') {
      renderSpendingByCategoryChart('spending-by-category-chart', spendingByCategoryData);
    }
  }
  
  if (document.getElementById('monthly-spending-trend-chart')) {
    if (typeof monthlySpendingTrendData !== 'undefined') {
      renderMonthlySpendingTrendChart('monthly-spending-trend-chart', monthlySpendingTrendData);
    }
  }
  
  if (document.getElementById('budget-vs-actual-chart')) {
    if (typeof budgetVsActualData !== 'undefined') {
      renderBudgetVsActualChart('budget-vs-actual-chart', budgetVsActualData);
    }
  }
  
  if (document.getElementById('goals-progress-chart')) {
    if (typeof goalsProgressData !== 'undefined') {
      renderGoalsProgressChart('goals-progress-chart', goalsProgressData);
    }
  }
});
