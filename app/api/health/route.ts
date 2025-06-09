import {NextResponse} from 'next/server';

export async function GET() {
    const response = NextResponse.json(
        {
            message: 'Health check passed.'
        },
    );

    // Set cache headers
    response.headers.set('Cache-Control', 'no-store');
    response.headers.set('Pragma', 'no-cache');
    response.headers.set('Expires', '0');

    return response;
}

export async function POST(request: Request) {
    let body = {}

    try {
        body = await request.json();
    } catch (e) {
        console.log(e)
    }

    return NextResponse.json(
        {
            message: 'POST request received!',
            data: body
        }
    );
}
