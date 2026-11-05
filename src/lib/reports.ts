// Project report PDFs live in the private "reports" storage bucket at <project_id>/<cycle_id>.pdf.
// Who can read them is enforced by storage policies (migration 0012).
export const REPORTS_BUCKET = 'reports';
export const reportPath = (projectId: string, cycleId: string) => `${projectId}/${cycleId}.pdf`;
export const MAX_REPORT_BYTES = 10 * 1024 * 1024;
