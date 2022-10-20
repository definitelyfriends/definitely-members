export class ResponseError extends Error {
  status?: number;
  code?: "CUSTOM_ERROR";
}

async function validateResponse(response: Response) {
  if (!response.ok) {
    const error: ResponseError = new Error("Something went wrong");
    const json = await response.json();
    error.message = json.message || undefined;
    error.status = response.status;
    throw error;
  }
}

export async function fetchGetJSON(url: string) {
  try {
    const response = await fetch(url);
    await validateResponse(response);
    return await response.json();
  } catch (err) {
    throw err;
  }
}

export async function fetchPostJSON(url: string, data?: {}) {
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(data || {}),
    });

    await validateResponse(response);
    return await response.json();
  } catch (err) {
    throw err;
  }
}
