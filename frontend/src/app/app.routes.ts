import { Routes } from '@angular/router';
import { authGuard } from './core/auth.guard';

export const routes: Routes = [
  {
    path: 'login',
    title: 'Sign in',
    loadComponent: () => import('./pages/login/login.page').then((m) => m.LoginPage),
  },
  {
    path: '',
    canActivateChild: [authGuard],
    children: [
      { path: '', pathMatch: 'full', redirectTo: 'dashboard' },
      {
        path: 'dashboard',
        title: 'Dashboard',
        loadComponent: () => import('./pages/dashboard/dashboard.page').then((m) => m.DashboardPage),
      },
      {
        path: 'employees',
        title: 'Employees',
        loadComponent: () => import('./pages/employee-list/employee-list.page').then((m) => m.EmployeeListPage),
      },
      {
        path: 'employees/new',
        title: 'Add Employee',
        loadComponent: () => import('./pages/employee-form/employee-form.page').then((m) => m.EmployeeFormPage),
      },
      {
        path: 'employees/:id/edit',
        title: 'Edit Employee',
        loadComponent: () => import('./pages/employee-form/employee-form.page').then((m) => m.EmployeeFormPage),
      },
      {
        path: 'employees/:id',
        title: 'Employee',
        loadComponent: () => import('./pages/employee-detail/employee-detail.page').then((m) => m.EmployeeDetailPage),
      },
      {
        path: 'insights',
        title: 'Salary Insights',
        loadComponent: () => import('./pages/insights/insights.page').then((m) => m.InsightsPage),
      },
    ],
  },
  { path: '**', redirectTo: 'dashboard' },
];
