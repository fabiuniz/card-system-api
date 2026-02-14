import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClientModule, HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, FormsModule, HttpClientModule],
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent {
  form = { cardNumber: '', amount: 0 };
  loading = false;
  result: any = null;

  constructor(private http: HttpClient) {}

  sendTransaction() {
    if (!this.form.cardNumber || this.form.amount <= 0) return alert('Preencha os dados!');
    this.loading = true;
    this.http.post('/api/v1/transactions', this.form).subscribe({
      next: (res) => { this.result = res; this.loading = false; },
      error: (err) => { 
        this.result = err.status === 422 ? err.error : { status: 'ERROR', reason: 'Falha na API' };
        this.loading = false; 
      }
    });
  }
}
