import { NextResponse, type NextRequest } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { REPORTS_BUCKET, reportPath } from '@/lib/reports';

// Opens a project's report through a 60-second signed link. Storage policies decide who may read it,
// so a consultant or a lead from another project gets a 404 here.
export async function GET(_req: NextRequest, { params }: { params: Promise<{ projectId: string }> }) {
  const { projectId } = await params;
  const sb = await createClient();
  const { data: cycleId } = await sb.rpc('current_or_latest_cycle');
  if (!cycleId) return new NextResponse('Not found', { status: 404 });
  const { data, error } = await sb.storage.from(REPORTS_BUCKET).createSignedUrl(reportPath(projectId, cycleId), 60);
  if (error || !data) return new NextResponse('Not found', { status: 404 });
  return NextResponse.redirect(data.signedUrl);
}
